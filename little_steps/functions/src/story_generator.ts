import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Anthropic from "@anthropic-ai/sdk";

const db = admin.firestore();

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

    // Fetch memories for the month
    const [year, month] = monthKey.split("-").map(Number);
    const startDate = new Date(year, month - 1, 1).toISOString();
    const endDate = new Date(year, month, 0, 23, 59, 59).toISOString();

    const memoriesSnap = await db
      .collection("families")
      .doc(familyId)
      .collection("memories")
      .where("takenAt", ">=", startDate)
      .where("takenAt", "<=", endDate)
      .orderBy("takenAt")
      .get();

    if (memoriesSnap.empty) {
      throw new functions.https.HttpsError(
        "not-found",
        "No memories found for this month."
      );
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
      const date = data.takenAt?.substring(0, 10) ?? "";
      return `- ${date}: ${caption || "photo"} [tags: ${tags.join(", ") || "none"}]`;
    });

    const monthNames = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];
    const monthName = monthNames[month];

    const prompt = `You are writing a warm, personal monthly memory story for a baby's digital memory book.

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

    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "ANTHROPIC_API_KEY not configured."
      );
    }

    const anthropic = new Anthropic({ apiKey });
    const message = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 600,
      messages: [{ role: "user", content: prompt }],
    });

    const fullText =
      message.content[0].type === "text" ? message.content[0].text : "";
    const lines = fullText.split("\n").filter((l) => l.trim());
    const title = lines[0] ?? `${monthName} ${year}`;
    const content = lines.slice(1).join("\n\n").trim();

    // Pick up to 4 photo URLs from memories
    const photoUrls: string[] = memoriesSnap.docs
      .slice(0, 4)
      .map((d) => d.data().thumbnailUrl as string)
      .filter(Boolean);

    const storyId = monthKey;
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
      });

    return { storyId };
  }
);
