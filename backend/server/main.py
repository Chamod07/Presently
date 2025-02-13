# uvicorn main:app --reload (to start the server)

from fastapi import FastAPI
from controllers.TaskAssignController import router
from controllers.user_report_controller import router as user_report_router


app = FastAPI(title="Presently Backend")

# Include the router from TaskAssignController
app.include_router(router)
app.include_router(user_report_router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)