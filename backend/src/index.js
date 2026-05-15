require('dotenv').config();
const express = require('express');
const cors = require('cors');
const roomRoutes = require('./routes/rooms');
const voteRoutes = require('./routes/votes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/rooms', roomRoutes);
app.use('/api/votes', voteRoutes);

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

app.listen(PORT, () => {
  console.log(`IRV Voting API running on port ${PORT}`);
});