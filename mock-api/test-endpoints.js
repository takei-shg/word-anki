const http = require('http');

const baseUrl = 'http://localhost:3000';

// Helper function to make HTTP requests
function makeRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const jsonBody = JSON.parse(body);
          resolve({ status: res.statusCode, data: jsonBody });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

// Test endpoints
async function testEndpoints() {
  console.log('Testing Mock API Endpoints...\n');

  try {
    // Test 1: Get all text sources
    console.log('1. Testing GET /api/text-sources');
    const sources = await makeRequest('/api/text-sources');
    console.log(`   Status: ${sources.status}`);
    console.log(`   Sources count: ${sources.data.length}`);
    console.log(`   First source: ${sources.data[0]?.title}\n`);

    // Test 2: Get word tests for a specific source
    const sourceId = sources.data[0]?.id;
    if (sourceId) {
      console.log(`2. Testing GET /api/text-sources/${sourceId}/word-tests`);
      const wordTests = await makeRequest(`/api/text-sources/${sourceId}/word-tests`);
      console.log(`   Status: ${wordTests.status}`);
      console.log(`   Word tests count: ${wordTests.data.length}`);
      console.log(`   First word: ${wordTests.data[0]?.word}\n`);
    }

    // Test 3: Get word tests by difficulty
    console.log('3. Testing GET /api/word-tests/by-difficulty/intermediate');
    const intermediateWords = await makeRequest('/api/word-tests/by-difficulty/intermediate');
    console.log(`   Status: ${intermediateWords.status}`);
    console.log(`   Intermediate words count: ${intermediateWords.data.length}\n`);

    // Test 4: Get user progress
    console.log('4. Testing GET /api/user-progress');
    const progress = await makeRequest('/api/user-progress');
    console.log(`   Status: ${progress.status}`);
    console.log(`   Progress entries count: ${progress.data.length}\n`);

    console.log('✅ All endpoint tests completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run tests
testEndpoints();