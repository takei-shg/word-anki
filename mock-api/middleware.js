module.exports = (req, res, next) => {
  // Enable CORS for iOS simulator
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
    return;
  }

  // Custom middleware for text source upload simulation
  if (req.method === 'POST' && req.path === '/api/text-sources') {
    // Simulate processing delay
    setTimeout(() => {
      // Add processing metadata
      req.body.id = generateUUID();
      req.body.uploadDate = new Date().toISOString();
      req.body.processedDate = null;
      req.body.isProcessed = false;
      req.body.wordCount = req.body.content ? req.body.content.split(' ').length : 0;
      
      // Simulate processing completion after 3 seconds
      setTimeout(() => {
        req.body.processedDate = new Date().toISOString();
        req.body.isProcessed = true;
      }, 3000);
      
      next();
    }, 1000);
    return;
  }

  // Custom middleware for progress sync
  if (req.method === 'POST' && req.path === '/api/sync/progress') {
    // Mark all progress items as synced
    if (Array.isArray(req.body)) {
      req.body = req.body.map(progress => ({
        ...progress,
        isSynced: true,
        id: progress.id || generateUUID()
      }));
    }
  }

  // Add request logging
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  
  next();
};

// Helper function to generate UUIDs
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}