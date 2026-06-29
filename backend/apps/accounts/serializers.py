from django.contrib.auth.models import User
from rest_framework import serializers

from .models import MemberProfile, create_member_profile, normalize_handle


class MemberProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = MemberProfile
        fields = (
            "display_name",
            "handle",
            "avatar",
            "bio",
            "role",
            "joined_at",
            "last_active_at",
            "thread_count",
            "reply_count",
            "helpful_received_count",
            "is_banned",
        )
        read_only_fields = fields


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    display_name = serializers.CharField(max_length=100)
    handle = serializers.CharField(max_length=30, required=False, allow_blank=True)

    def validate_email(self, value: str) -> str:
        email = value.lower().strip()
        if User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError("A member with this email already exists.")
        if User.objects.filter(username__iexact=email).exists():
            raise serializers.ValidationError("A member with this email already exists.")
        return email

    def validate_handle(self, value: str) -> str:
        if not value:
            return value
        handle = normalize_handle(value)
        if len(handle) < 3:
            raise serializers.ValidationError(
                "Handle must be at least 3 characters (letters, numbers, underscore)."
            )
        if MemberProfile.objects.filter(handle=handle).exists():
            raise serializers.ValidationError("This handle is already taken.")
        return handle

    def create(self, validated_data):
        email = validated_data["email"]
        user = User.objects.create_user(
            username=email,
            email=email,
            password=validated_data["password"],
        )
        profile = create_member_profile(
            user=user,
            display_name=validated_data["display_name"],
            handle=validated_data.get("handle") or None,
        )
        return user, profile


class MeSerializer(serializers.ModelSerializer):
    profile = MemberProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ("id", "email", "profile")
        read_only_fields = fields
