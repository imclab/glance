curl -X PUT http://127.0.0.1:5984/chi2013/_design/session -d @session.json
curl -X PUT http://127.0.0.1:5984/chi2013/_design/submission -d @submission.json
curl -X PUT http://127.0.0.1:5984/chi2013/_design/day -d @day.json
curl -X PUT http://127.0.0.1:5984/chi2013/_design/timeslot -d @timeslot.json