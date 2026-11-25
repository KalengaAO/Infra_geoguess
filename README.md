# Infra_geoguess
Infrastrutura-GeoGuess Angola



# health check page view
https://gueoguessangola/status/ 


# Popular database 
docker compose exec backend python manage.py loaddata geo_locations_fixture.json
### verificar
from game.models import GeoLocation

print(GeoLocation.objects.count())
