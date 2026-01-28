from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import users
# Database tables are managed via Supabase dashboard/SQL


app = FastAPI(title="EcoSnap API", version="0.1.0")

# CORS middleware to allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development, allow all. Restrict in production.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/users", tags=["users"])
from app.api.routes import analysis, chat, gamification
app.include_router(analysis.router, prefix="/analysis", tags=["analysis"])
app.include_router(chat.router, prefix="/chat", tags=["chat"])
app.include_router(gamification.router, prefix="/gamification", tags=["gamification"])

from app.api.routes import community, subsidies, predictive, carbon
app.include_router(community.router, prefix="/community", tags=["community"])
app.include_router(subsidies.router, prefix="/subsidies", tags=["subsidies"])
app.include_router(predictive.router, prefix="/predictive", tags=["predictive"])
app.include_router(carbon.router, prefix="/carbon", tags=["carbon"])

@app.get("/")
async def root():
    return {"message": "Welcome to EcoSnap API", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "ok"}
