from django.contrib.auth.models import User
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from accounts.models import MemberProfile


class AuthAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_register_login_me_logout(self):
        register_url = reverse("auth-register")
        response = self.client.post(
            register_url,
            {
                "email": "test@example.com",
                "password": "testpass123",
                "display_name": "Test Member",
                "handle": "test_member",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("tokens", response.data)
        self.assertEqual(response.data["user"]["profile"]["handle"], "test_member")

        login_url = reverse("auth-login")
        login_response = self.client.post(
            login_url,
            {"username": "test@example.com", "password": "testpass123"},
            format="json",
        )
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        access = login_response.data["access"]
        refresh = login_response.data["refresh"]

        me_url = reverse("me")
        me_response = self.client.get(
            me_url,
            HTTP_AUTHORIZATION=f"Bearer {access}",
        )
        self.assertEqual(me_response.status_code, status.HTTP_200_OK)
        self.assertEqual(me_response.data["email"], "test@example.com")

        logout_url = reverse("auth-logout")
        logout_response = self.client.post(
            logout_url,
            {"refresh": refresh},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {access}",
        )
        self.assertEqual(logout_response.status_code, status.HTTP_204_NO_CONTENT)

    def test_duplicate_email_rejected(self):
        User.objects.create_user(
            username="existing@example.com",
            email="existing@example.com",
            password="testpass123",
        )
        MemberProfile.objects.create(
            user=User.objects.get(email="existing@example.com"),
            display_name="Existing",
            handle="existing",
        )
        response = self.client.post(
            reverse("auth-register"),
            {
                "email": "existing@example.com",
                "password": "testpass123",
                "display_name": "Another",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
