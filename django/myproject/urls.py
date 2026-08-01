"""
URL configuration for myproject project.
"""
from django.contrib import admin
from django.urls import include, path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('healthz/', views.healthz, name='healthz'),
    path('load/', views.load, name='load'),
    path('admin/', admin.site.urls),
    # /metrics, scraped through the ServiceMonitor in the chart.
    path('', include('django_prometheus.urls')),
]
