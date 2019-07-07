# -*- coding: utf-8 -*-
# Generated by Django 1.9.7 on 2016-06-22 18:21
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('dcim', '0002_auto_20160622_1821'),
        ('auth', '0007_alter_validators_add_error_messages'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Secret',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created', models.DateField(auto_now_add=True)),
                ('last_updated', models.DateTimeField(auto_now=True)),
                ('name', models.CharField(blank=True, max_length=100)),
                ('ciphertext', models.BinaryField(max_length=65568)),
                ('hash', models.CharField(editable=False, max_length=128)),
                ('device', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='secrets', to='dcim.Device')),
            ],
            options={
                'ordering': ['device', 'role', 'name'],
            },
        ),
        migrations.CreateModel(
            name='SecretRole',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=50, unique=True)),
                ('slug', models.SlugField(unique=True)),
                ('groups', models.ManyToManyField(blank=True, related_name='secretroles', to='auth.Group')),
                ('users', models.ManyToManyField(blank=True, related_name='secretroles', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['name'],
            },
        ),
        migrations.CreateModel(
            name='UserKey',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created', models.DateField(auto_now_add=True)),
                ('last_updated', models.DateTimeField(auto_now=True)),
                ('public_key', models.TextField(verbose_name=b'RSA public key')),
                ('master_key_cipher', models.BinaryField(blank=True, max_length=512, null=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='user_key', to=settings.AUTH_USER_MODEL, verbose_name=b'User')),
            ],
            options={
                'ordering': ['user__username'],
                'permissions': (('activate_userkey', 'Can activate user keys for decryption'),),
            },
        ),
        migrations.AddField(
            model_name='secret',
            name='role',
            field=models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='secrets', to='secrets.SecretRole'),
        ),
        migrations.AlterUniqueTogether(
            name='secret',
            unique_together=set([('device', 'role', 'name')]),
        ),
    ]