from fastapi import FastAPI

from src.env import config

app = FastAPI()


@app.get("/")
def read_root():
    MODE = config("MODE", default="test", cast=str)
    return {"Hello": "World", "mode": MODE}
