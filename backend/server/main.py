# uvicorn main:app --reload (to start the server)

from fastapi import FastAPI
from controllers.TaskAssignController import router

app = FastAPI(title="Presently Backend")

# Include the router from TaskAssignController
app.include_router(router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)   
