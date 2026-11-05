"""Independent Python preflight for NY/South Africa and broker-date conversions.
Not a MetaTrader compilation or trading backtest.
"""
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo
from calendar import monthrange
from pathlib import Path
import csv

NY=ZoneInfo('America/New_York'); ZA=ZoneInfo('Africa/Johannesburg')
EU=ZoneInfo('Europe/Helsinki') # UTC+2 winter, UTC+3 summer

def first_sunday(y,m):
    d=datetime(y,m,1)
    return 1+(6-d.weekday())%7

def last_sunday(y,m):
    d=datetime(y,m,monthrange(y,m)[1])
    return d.day-(d.weekday()+1)%7

def us_dst_bounds_utc(y):
    return (datetime(y,3,first_sunday(y,3)+7,7,tzinfo=timezone.utc),
            datetime(y,11,first_sunday(y,11),6,tzinfo=timezone.utc))

def utc_to_ny_server_time(broker_local, mode='fixed', winter=2, summer=3):
    # Broker local is a naive wall-clock datetime, as in MQL5 server bars.
    y=broker_local.year
    offset=winter
    if mode=='eu':
        start=datetime(y,3,last_sunday(y,3),1)+timedelta(hours=winter)
        end=datetime(y,10,last_sunday(y,10),1)+timedelta(hours=summer)
        if start<=broker_local<end: offset=summer
    elif mode=='us':
        s,e=us_dst_bounds_utc(y)
        start=s.replace(tzinfo=None)+timedelta(hours=winter)
        end=e.replace(tzinfo=None)+timedelta(hours=summer)
        if start<=broker_local<end: offset=summer
    utc=(broker_local-timedelta(hours=offset)).replace(tzinfo=timezone.utc)
    s,e=us_dst_bounds_utc(utc.year)
    return (utc+timedelta(hours=-4 if s<=utc<e else -5)).replace(tzinfo=None)

windows=[('London premarket RESEARCH',0,90),('London opening range',90,120),
         ('London killzone',120,300),('London silver bullet',180,240),
         ('NY early opening range',420,450),('NY premarket research',420,570),
         ('NY equity opening range',570,600),('NY afternoon opening range',810,840)]
rows=[]
for date in ['2026-01-15','2026-07-15','2026-11-05']:
    y,m,d=map(int,date.split('-'))
    for name,st,en in windows:
        ny_start=datetime(y,m,d,tzinfo=NY)+timedelta(minutes=st)
        ny_end=datetime(y,m,d,tzinfo=NY)+timedelta(minutes=en)
        za_start=ny_start.astimezone(ZA);za_end=ny_end.astimezone(ZA)
        rows.append([date,name,ny_start.strftime('%H:%M'),ny_end.strftime('%H:%M'),
                     za_start.strftime('%H:%M'),za_end.strftime('%H:%M')])

for date in ['2022-01-15','2022-07-15','2023-01-15','2023-07-15','2024-01-15','2024-07-15',
             '2025-01-15','2025-07-15','2026-01-15','2026-07-15',
             '2026-03-15','2026-04-15','2026-10-15','2026-11-05']:
    y,m,d=map(int,date.split('-'))
    for hh in [1,3,9,15,21]:
        broker_aware=datetime(y,m,d,hh,30,tzinfo=EU)
        manual=utc_to_ny_server_time(broker_aware.replace(tzinfo=None),mode='eu')
        actual=broker_aware.astimezone(NY).replace(tzinfo=None)
        assert manual==actual,(broker_aware,manual,actual)
    # fixed broker +2 independent of DST
    for hh in [3,7,11]:
        broker=datetime(y,m,d,hh,30)
        expected=(broker.replace(tzinfo=timezone(timedelta(hours=2)))).astimezone(NY).replace(tzinfo=None)
        assert utc_to_ny_server_time(broker,'fixed',2)==expected
assert rows[1][-2:]==['08:30','09:00']
assert rows[9][-2:]==['07:30','08:00']
assert rows[17][-2:]==['08:30','09:00']

out=Path('/mnt/data/ICT_v12_NY_to_SAST_session_check.csv')
with out.open('w',newline='') as f:
    w=csv.writer(f);w.writerow(['date','study_window','ny_start','ny_end','sast_start','sast_end']);w.writerows(rows)
print('PASS: 14 historical spot dates x 8 broker cases across fixed and EU-DST clocks.')
print('PASS: Jan/Jul/Nov 2026 session mapping checked.')
print('CSV:',out,'rows:',len(rows))
