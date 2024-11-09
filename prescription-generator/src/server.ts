// src/config/prompts.ts

// src/server.ts
import express, { Request, Response } from 'express';
import multer from 'multer';
import cors from 'cors';
import { OpenAI } from 'openai';
import * as dotenv from 'dotenv';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { systemPrompt } from './config/prompts';

dotenv.config();

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

// Configure OpenAI
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Configure Google AI
const genai = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY || '');
const geminiModel = genai.getGenerativeModel({ model: 'gemini-1.5-flash' });

app.use(cors());
app.use(express.json());

const SUPPORTED_AUDIO_FORMATS = [
  '.flac', '.m4a', '.mp3', '.mp4', '.mpeg',
  '.mpga', '.oga', '.ogg', '.wav', '.webm'
];

app.post('/transcribe', upload.single('file'), async (req: Request, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No audio file provided.' });
    }

    const filename = req.file.originalname.toLowerCase();
    if (!SUPPORTED_AUDIO_FORMATS.some(format => filename.endsWith(format))) {
      return res.status(400).json({
        error: `Unsupported audio format. Supported formats: ${SUPPORTED_AUDIO_FORMATS.join(', ')}`
      });
    }

    const transcript = await openai.audio.transcriptions.create({
      file: new File([req.file.buffer], req.file.originalname, { type: req.file.mimetype, lastModified: Date.now() }),
      model: 'whisper-1',
      response_format: 'text'
    });

    return res.json({ transcription: transcript });
  } catch (error: any) {
    console.error('Transcription error:', error);
    return res.status(500).json({ error: `Transcription failed: ${error.message}` });
  }
});

app.post('/generate_prescription', async (req: Request, res: Response) => {
  try {
    const { transcription, location = 'xxxxxxx' } = req.body;

    if (!transcription) {
      return res.status(400).json({ error: 'Transcription text not provided.' });
    }

    const currentDate = new Date().toLocaleString('en-IN', {
      timeZone: 'Asia/Kolkata',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).split(',')[0];

    const systemPromptWithContext = `${systemPrompt}\n\nDate: ${currentDate}\nLocation: ${location}`;
    
    const result = await geminiModel.generateContent([systemPromptWithContext, transcription]);
    const prescription = result.response.text();

    return res.json({ prescription });
  } catch (error: any) {
    console.error('Prescription generation error:', error);
    return res.status(500).json({ 
      error: `Prescription generation failed: ${error.message}` 
    });
  }
});

app.post('/test', (_req: Request, res: Response) => {
  res.send('Test Successful');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});