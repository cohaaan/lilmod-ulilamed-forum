from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/", include("accounts.urls")),
]

admin.site.site_header = "Lilmod Ulilamed Admin"
admin.site.site_title = "Lilmod Ulilamed"
admin.site.index_title = "Forum administration"
