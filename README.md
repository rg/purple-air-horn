# purple-air-horn
Script that sends text alerts on changes in air quality level, as measured by a specified Purple Air sensor.

Designed to be run via cron job, one per Purple Air sensor ID, configured by `ENV` variables. Example:

```
PURPLE_AIR_SENSOR_ID=12345
CONVERSION='AQandU'
PHONE_NUMBERS='+15551234567'
* * * * * /path/to/ruby /home/purple-air-horn/air_horn.rb >> /home/log/sensor.${PURPLE_AIR_SENSOR_ID}.log 2>&1

```
