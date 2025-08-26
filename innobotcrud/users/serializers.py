from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    profile_picture = serializers.ImageField(use_url=True, required=False)
    
    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'phone_number', 'address', 'age', 'profile_picture']