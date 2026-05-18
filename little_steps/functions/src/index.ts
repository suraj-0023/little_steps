import * as admin from "firebase-admin";

admin.initializeApp();

export { generateMonthlyStory } from "./story_generator";
