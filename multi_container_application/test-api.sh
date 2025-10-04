#!/bin/bash

# Test script for Todo API
BASE_URL=${1:-http://localhost}

echo "Testing Todo API at: $BASE_URL"
echo "================================"

echo -e "\n1. Health Check"
curl -s $BASE_URL/ | jq '.'

echo -e "\n2. Get All Todos"
curl -s $BASE_URL/todos | jq '.'

echo -e "\n3. Create Todo"
TODO=$(curl -s -X POST $BASE_URL/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Docker Compose", "completed": false}')
echo $TODO | jq '.'
TODO_ID=$(echo $TODO | jq -r '._id')

echo -e "\n4. Get Single Todo"
curl -s $BASE_URL/todos/$TODO_ID | jq '.'

echo -e "\n5. Update Todo"
curl -s -X PUT $BASE_URL/todos/$TODO_ID \
  -H "Content-Type: application/json" \
  -d '{"completed": true}' | jq '.'

echo -e "\n6. Delete Todo"
curl -s -X DELETE $BASE_URL/todos/$TODO_ID | jq '.'

echo -e "\nTesting complete!"