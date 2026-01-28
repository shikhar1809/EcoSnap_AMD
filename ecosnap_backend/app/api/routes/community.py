from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import uuid

router = APIRouter()

# In-memory storage for MVP (since we can't easily create tables)
# In a real app, this would be Supabase tables: questions, answers
questions_db = []
answers_db = []

class QuestionCreate(BaseModel):
    user_id: str
    user_name: str
    title: str
    content: str
    category: str = "General"
    city: Optional[str] = None

class AnswerCreate(BaseModel):
    user_id: str
    user_name: str
    question_id: str
    content: str

class Question(QuestionCreate):
    id: str
    created_at: str
    upvotes: int = 0
    answer_count: int = 0

class Answer(AnswerCreate):
    id: str
    created_at: str
    upvotes: int = 0
    is_expert: bool = False

@router.post("/questions", response_model=Question)
async def ask_question(q: QuestionCreate):
    new_q = Question(
        **q.dict(),
        id=str(uuid.uuid4()),
        created_at=datetime.now().isoformat()
    )
    questions_db.append(new_q)
    return new_q

@router.get("/questions", response_model=List[Question])
async def list_questions(category: Optional[str] = None, city: Optional[str] = None):
    results = questions_db
    if category:
        results = [q for q in results if q.category == category]
    if city:
        results = [q for q in results if q.city == city]
    return sorted(results, key=lambda x: x.created_at, reverse=True)

@router.post("/answers", response_model=Answer)
async def answer_question(a: AnswerCreate):
    # Check if question exists
    q_exists = next((q for q in questions_db if q.id == a.question_id), None)
    if not q_exists:
        raise HTTPException(status_code=404, detail="Question not found")
    
    new_a = Answer(
        **a.dict(),
        id=str(uuid.uuid4()),
        created_at=datetime.now().isoformat()
    )
    answers_db.append(new_a)
    
    # Update answer count
    q_exists.answer_count += 1
    
    return new_a

@router.get("/questions/{question_id}/answers", response_model=List[Answer])
async def get_answers(question_id: str):
    return [a for a in answers_db if a.question_id == question_id]

@router.post("/vote")
async def vote(item_id: str, item_type: str = "question"): # item_type: question or answer
    if item_type == "question":
        item = next((q for q in questions_db if q.id == item_id), None)
    else:
        item = next((a for a in answers_db if a.id == item_id), None)
        
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
        
    item.upvotes += 1
    return {"message": "Upvoted", "new_count": item.upvotes}
