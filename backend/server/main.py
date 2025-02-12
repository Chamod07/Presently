# uvicorn main:app --reload (to start the server)

from fastapi import FastAPI
from server.controllers.TaskAssignController import router

app = FastAPI(title="Presently Backend")

# Include the router from TaskAssignController
app.include_router(router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)