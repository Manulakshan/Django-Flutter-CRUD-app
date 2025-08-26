# 👥 User Management System (Flutter Web + Django REST)

A full-stack **User Management System** built with **Flutter Web** (frontend) and **Django REST Framework** (backend).  
This project allows you to **create, read, update, and delete (CRUD)** users with profile pictures, responsive UI, and API integration.  


Features
-  **User Management**: Create, Read, Update, and Delete users  
-  **Responsive Design**: Works seamlessly on desktop and mobile  
-  **Profile Pictures**: Upload and display user profile images  
-  **Pagination**: Efficiently browse through user lists  
-  **Real-time Updates**: Automatic UI refresh on actions

Perequisites
Make sure you have installed:  
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable)  
- [Dart SDK](https://dart.dev/get-dart) (latest stable)  
- [Python](https://www.python.org/downloads/)  
- [pip](https://pip.pypa.io/en/stable/installation/) (Python package manager)  
- [PostgreSQL](https://www.postgresql.org/download/)

** Backend Setup (Django)**

1. Navigate to the backend folder:
   ```bash
   cd innobotcrud

2.Create and activate a virtual environment:
   # Windows
    python -m venv venv
    .\venv\Scripts\activate

  # macOS/Linux
    python3 -m venv venv
    source venv/bin/activate

3. Database setup:
    PostgreSQL: update DATABASES in innobotcrud/settings.py

4.Run migrations:
    python manage.py migrate

5.Run the development server:
    python manage.py runserver

**  Frontend Setup (Flutter Web)**

1. Navigate to the frontend folder:
   cd crud_flutter_web
   
2. Install dependencies:
   flutter pub get
   
3. Run the app:
   flutter run -d chrome --web-port=3000

 **  The app will be available at: http://localhost:3000**

 ⚙️ Environment Variables

 Backend (.env in innobotcrud/)
 
 DEBUG=True
  SECRET_KEY=your-secret-key
  DATABASE_URL=sqlite:///db.sqlite3 or set up postgres
  ALLOWED_HOSTS=localhost,127.0.0.1
  CORS_ALLOWED_ORIGINS=http://localhost:3000

Frontend (.env in crud_flutter_web/)

API_BASE_URL=http://127.0.0.1:8000/api

innobot_crud/
├── crud_flutter_web/       # Flutter frontend
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── screens/        # App screens
│   │   ├── services/       # API services
│   │   └── widgets/        # Reusable widgets
│   └── pubspec.yaml        # Flutter dependencies
│
└── innobotcrud/            # Django backend
    ├── innobotcrud/        # Project settings
    ├── users/              # Users app
    └── manage.py           # Django management script

 🛠️ Troubleshooting

**  CORS Issues**
  Ensure CORS is enabled in settings.py
  Verify frontend URL is in CORS_ALLOWED_ORIGINS
  
**  Database Errors**
  Check DB credentials in settings.py
  Run python manage.py migrate
  
**  Flutter Issues**
  Run flutter clean && flutter pub get
  Make sure Flutter is updated (flutter upgrade)
   

  

  

    
