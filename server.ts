import express from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createServer as createViteServer } from 'vite';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DATA_FILE = path.join(__dirname, 'habits_data.json');

// Initialize data file if it doesn't exist
try {
  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify({
      habits: [],
      completedHabits: [],
      completions: {},
      reflections: {},
      todos: [],
      userName: ''
    }, null, 2));
  }
} catch (error) {
  console.warn('Could not initialize data file:', error);
}

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json({ limit: '10mb' }));

  // API Routes
  app.get('/api/data', (req, res) => {
    try {
      if (!fs.existsSync(DATA_FILE)) {
        const defaultData = { habits: [], completedHabits: [], completions: {}, reflections: {}, todos: [], userName: '' };
        try {
          fs.writeFileSync(DATA_FILE, JSON.stringify(defaultData, null, 2));
        } catch (writeError) {
          console.warn('Could not write data file in GET route:', writeError);
        }
        return res.json(defaultData);
      }
      const data = fs.readFileSync(DATA_FILE, 'utf8');
      res.json(JSON.parse(data));
    } catch (error) {
      console.error('Error reading data:', error);
      res.status(500).json({ error: 'Failed to load data' });
    }
  });

  app.post('/api/data', (req, res) => {
    try {
      const data = req.body;
      fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
      res.json({ success: true });
    } catch (error) {
      console.error('Error saving data:', error);
      res.status(500).json({ error: 'Failed to save data' });
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.resolve(__dirname, 'dist');
    app.use(express.static(distPath));
    app.get('*all', (req, res) => {
      res.sendFile(path.resolve(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at http://localhost:${PORT}`);
  });
}

startServer();
