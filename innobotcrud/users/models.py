from django.db import models

# Create your models here.
class User(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=12,blank=True,null=True)
    address = models.TextField(blank=True, null=True)
    age = models.IntegerField(blank=True,null=True)
    profile_picture = models.ImageField(upload_to='profiles/',blank=True, null=True)

def __str__(self):
    return self.name
