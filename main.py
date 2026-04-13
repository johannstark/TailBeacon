from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
def read_health_check():
    """
    Simple health check endpoint that confirms the server is running.
    """
    return {"status": "ok"}
