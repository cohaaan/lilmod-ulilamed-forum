import re

from django.conf import settings
from django.contrib.auth.models import User
from django.db import models
from django.utils.text import slugify


class MemberProfile(models.Model):
    class Role(models.TextChoices):
        MEMBER = "member", "Member"
        MODERATOR = "moderator", "Moderator"
        ADMIN = "admin", "Admin"

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile",
    )
    display_name = models.CharField(max_length=100)
    handle = models.SlugField(max_length=50, unique=True)
    avatar = models.ImageField(upload_to="avatars/", blank=True)
    bio = models.TextField(blank=True)
    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.MEMBER,
    )
    joined_at = models.DateTimeField(auto_now_add=True)
    last_active_at = models.DateTimeField(null=True, blank=True)
    thread_count = models.PositiveIntegerField(default=0)
    reply_count = models.PositiveIntegerField(default=0)
    helpful_received_count = models.PositiveIntegerField(default=0)
    is_banned = models.BooleanField(default=False)

    class Meta:
        ordering = ["display_name"]

    def __str__(self) -> str:
        return self.display_name


HANDLE_PATTERN = re.compile(r"^[a-z0-9_]{3,30}$")


def normalize_handle(value: str) -> str:
    handle = slugify(value, allow_unicode=False).replace("-", "_").lower()
    handle = re.sub(r"[^a-z0-9_]", "", handle)
    return handle[:30]


def generate_unique_handle(base: str) -> str:
    candidate = normalize_handle(base) or "member"
    if not HANDLE_PATTERN.match(candidate):
        candidate = "member"
    if not MemberProfile.objects.filter(handle=candidate).exists():
        return candidate
    suffix = 2
    while True:
        truncated = candidate[: max(1, 30 - len(str(suffix)) - 1)]
        next_handle = f"{truncated}_{suffix}"
        if not MemberProfile.objects.filter(handle=next_handle).exists():
            return next_handle
        suffix += 1


def create_member_profile(
    *,
    user: User,
    display_name: str,
    handle: str | None = None,
) -> MemberProfile:
    resolved_handle = normalize_handle(handle or display_name or user.username)
    if not HANDLE_PATTERN.match(resolved_handle):
        resolved_handle = generate_unique_handle(display_name or user.username)
    elif MemberProfile.objects.filter(handle=resolved_handle).exists():
        resolved_handle = generate_unique_handle(resolved_handle)

    return MemberProfile.objects.create(
        user=user,
        display_name=display_name.strip(),
        handle=resolved_handle,
    )
