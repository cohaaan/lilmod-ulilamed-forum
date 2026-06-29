from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User

from .models import MemberProfile


class MemberProfileInline(admin.StackedInline):
    model = MemberProfile
    can_delete = False
    fk_name = "user"
    readonly_fields = (
        "joined_at",
        "last_active_at",
        "thread_count",
        "reply_count",
        "helpful_received_count",
    )


class UserAdmin(BaseUserAdmin):
    inlines = (MemberProfileInline,)
    list_display = ("username", "email", "is_staff", "is_active", "date_joined")
    search_fields = ("username", "email", "profile__display_name", "profile__handle")


@admin.register(MemberProfile)
class MemberProfileAdmin(admin.ModelAdmin):
    list_display = (
        "display_name",
        "handle",
        "role",
        "is_banned",
        "thread_count",
        "reply_count",
        "joined_at",
    )
    list_filter = ("role", "is_banned")
    search_fields = ("display_name", "handle", "user__email")
    readonly_fields = (
        "joined_at",
        "last_active_at",
        "thread_count",
        "reply_count",
        "helpful_received_count",
    )


admin.site.unregister(User)
admin.site.register(User, UserAdmin)
