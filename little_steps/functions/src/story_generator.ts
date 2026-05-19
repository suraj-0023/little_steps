import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { VertexAI } from "@google-cloud/vertexai";
import { GoogleAuth } from "google-auth-library";

const db = admin.firestore();
const storage = admin.storage();

export const generateMonthlyStory = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be signed in.");
    }

    const { familyId, babyId, monthKey } = request.data as {
      familyId: string;
      babyId: string;
      monthKey: string; // "2026-05"
    };

    if (!familyId || !babyId || !monthKey) {
      throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
    }

    const projectId = process.env.GCLOUD_PROJECT!;
    const location = "us-central1";

    // Fetch memories for the month using Firestore Timestamps
    const [year, month] = monthKey.split("-").map(Number);
    const startDate = admin.firestore.Timestamp.fromDate(new Date(year, month - 1, 1));
    const endDate = admin.firestore.Timestamp.fromDate(new Date(year, month, 0, 23, 59, 59));

    const memoriesSnap = await db
      .collection("families")
      .doc(familyId)
      .collection("memories")
      .where("takenAt", ">=", startDate)
      .where("takenAt", "<=", endDate)
      .orderBy("takenAt")
      .get();

    if (memoriesSnap.empty) {
      throw new functions.https.HttpsError("not-found", "No memories found for this month.");
    }

    // Fetch baby name
    const babyDoc = await db
      .collection("families")
      .doc(familyId)
      .collection("babies")
      .doc(babyId)
      .get();
    const babyName: string = babyDoc.data()?.name?.split(" ")[0] ?? "Baby";

    // Build memory context
    const memorySummaries = memoriesSnap.docs.map((doc) => {
      const data = doc.data();
      const caption = data.caption ?? "";
      const tags: string[] = data.tags ?? [];
      const ts = data.takenAt as admin.firestore.Timestamp;
      const date = ts.toDate().toISOString().substring(0, 10);
      return `- ${date}: ${caption || "photo"} [tags: ${tags.join(", ") || "none"}]`;
    });

    const monthNames = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];
    const monthName = monthNames[month];

    // ── Gemini 2.0 Flash — generate story text ────────────────────────────
    const vertexAI = new VertexAI({ project: projectId, location });
    const geminiModel = vertexAI.getGenerativeModel({ model: "gemini-2.0-flash-001" });

    const storyPrompt = `You are writing a warm, personal monthly memory story for a baby's digital memory book.

Baby's name: ${babyName}
Month: ${monthName} ${year}
Number of memories: ${memorySummaries.length}

Memory summaries:
${memorySummaries.join("\n")}

Write a beautiful, heartfelt 2-3 paragraph narrative story about ${babyName}'s month.
Write in second person ("This month, you...").
Be warm, specific, and capture the magic of this stage of life.
Start with a title on the first line, then a blank line, then the story.
Do not use markdown formatting.`;

    const geminiResult = await geminiModel.generateContent(storyPrompt);
    const fullText =
      geminiResult.response.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const lines = fullText.split("\n").filter((l) => l.trim());
    const title = lines[0] ?? `${monthName} ${year}`;
    const content = lines.slice(1).join("\n\n").trim();

    // ── Imagen 3 — generate watercolor illustration ────────────────────────
    const storyId = monthKey;
    let illustrationUrl: string | undefined;

    try {
      const themeSnippet = memorySummaries
        .slice(0, 3)
        .map((s) => s.replace(/^- \d{4}-\d{2}-\d{2}: /, ""))
        .join("; ");

      const imagePrompt =
        `Watercolor illustration for a baby memory book. ` +
        `${monthName} ${year}. Baby named ${babyName}. ` +
        `Warm, cozy, soft pastel colours. Themes: ${themeSnippet}. ` +
        `Children's book style. No text or letters in the image.`;

      const auth = new GoogleAuth({
        scopes: ["https://www.googleapis.com/auth/cloud-platform"],
      });
      const authClient = await auth.getClient();
      const accessToken = await authClient.getAccessToken();

      const imagenRes = await fetch(
        `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}` +
          `/locations/${location}/publishers/google/models/imagen-3.0-generate-001:predict`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken.token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            instances: [{ prompt: imagePrompt }],
            parameters: {
              sampleCount: 1,
              aspectRatio: "16:9",
              safetyFilterLevel: "block_few",
            },
          }),
        }
      );

      const imagenData = await imagenRes.json() as {
        predictions?: Array<{ bytesBase64Encoded: string }>;
      };
      const base64Image = imagenData.predictions?.[0]?.bytesBase64Encoded;

      if (base64Image) {
        const bucket = storage.bucket();
        const filePath = `families/${familyId}/stories/${storyId}/illustration.jpg`;
        const file = bucket.file(filePath);
        await file.save(Buffer.from(base64Image, "base64"), {
          contentType: "image/jpeg",
          metadata: { cacheControl: "public, max-age=31536000" },
        });
        await file.makePublic();
        illustrationUrl = file.publicUrl();
      }
    } catch (imgErr) {
      // Illustration is best-effort — story is still saved without it
      console.error("Imagen 3 generation failed:", imgErr);
    }

    // Pick up to 4 memory photo thumbnails
    const photoUrls: string[] = memoriesSnap.docs
      .slice(0, 4)
      .map((d) => d.data().thumbnailUrl as string)
      .filter(Boolean);

    await db
      .collection("families")
      .doc(familyId)
      .collection("stories")
      .doc(storyId)
      .set({
        familyId,
        babyId,
        monthKey,
        title,
        content,
        generatedAt: new Date().toISOString(),
        photoUrls,
        memoryCount: memoriesSnap.size,
        ...(illustrationUrl ? { illustrationUrl } : {}),
      });

    return { storyId };
  }
);
