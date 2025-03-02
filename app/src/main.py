import os
from fastapi import FastAPI, HTTPException
from azure.cosmos import CosmosClient, exceptions
from azure.identity import DefaultAzureCredential

app = FastAPI()

# Cosmos DB configuration (without using a key)
COSMOS_URL = os.environ.get("COSMOS_URL", "https://cosmos-asgbdsfgegdfg.documents.azure.com:443/")
DATABASE_NAME = os.environ.get("COSMOS_DATABASE", "data")
CONTAINER_NAME = os.environ.get("COSMOS_CONTAINER", "users")

credential = DefaultAzureCredential()
client = CosmosClient(COSMOS_URL, credential=credential)
database = client.get_database_client(DATABASE_NAME)
container = database.get_container_client(CONTAINER_NAME)

@app.get("/health")
async def health():
    """
    Health check endpoint.
    """
    return {"status": "OK!"}

@app.post("/items")
async def create_item(item: dict):
    """
    Create a new item in the Cosmos DB container.
    The item must include an "id" field.
    """
    if "id" not in item:
        raise HTTPException(status_code=400, detail="Item must have an 'id' field")
    try:
        container.create_item(body=item)
        return {"message": "Item created successfully", "item": item}
    except exceptions.CosmosHttpResponseError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/items/{item_id}")
async def read_item(item_id: str):
    """
    Retrieve an item from the Cosmos DB container by its 'id'.
    """
    try:
        # Query the container for the item with the given id.
        query = f"SELECT * FROM c WHERE c.id = '{item_id}'"
        items = list(container.query_items(query=query, enable_cross_partition_query=True))
        if not items:
            raise HTTPException(status_code=404, detail="Item not found")
        return items[0]
    except exceptions.CosmosHttpResponseError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
