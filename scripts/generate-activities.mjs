import { GoogleGenerativeAI } from "@google/generative-ai";
import fs from "fs";

// Initialize the Gemini API with your API Key
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function generateActivitiesFromCommentary(commentaryChunks) {
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `
    You are a cricket data analyst. Given the following cricket commentary chunks, extract a list of significant "activities" or "events".
    Significant events include: Wickets, Boundaries (4s and 6s), Milestones (50s, 100s), and Match result.
    
    For each event, provide:
    - type: (wicket, four, six, milestone)
    - event: (e.g., "WICKET", "FOUR", "SIX", "FIFTY")
    - description: A concise summary of what happened.
    - commentary_snippet: The exact part of the commentary that describes the event.

    Return the result as a JSON array of objects.

    Commentary Chunks:
    ${JSON.stringify(commentaryChunks, null, 2)}
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    // Clean up the response to ensure it's valid JSON
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    return [];
  } catch (error) {
    console.error("Error generating activities:", error);
    return [];
  }
}

async function main() {
  if (!process.env.GEMINI_API_KEY) {
    console.error("Please set GEMINI_API_KEY environment variable.");
    process.exit(1);
  }

  const data = JSON.parse(fs.readFileSync("mock_data.json", "utf8"));
  const match = data.matches[0];
  
  console.log(`Generating activities for: ${match.title}...`);
  const activities = await generateActivitiesFromCommentary(match.commentary_chunks);
  
  match.activities = activities;
  
  fs.writeFileSync("mock_data.json", JSON.stringify(data, null, 2));
  console.log("Successfully updated mock_data.json with AI-generated activities.");
}

// main(); // Uncomment to run
