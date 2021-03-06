nano = require('nano')('http://127.0.0.1:5984')
sets = require 'simplesets'
_ = require 'underscore'

chidb = nano.db.use('chi2013');

submissionData = require('./' + process.argv[2]).rows
sessionData = require('./' + process.argv[3]).rows
schedule = require('./' + process.argv[4]).rows
interactivity = require('./' + process.argv[5]).rows
letterCodes = require './letterCodes.json'
codesWithVideos = require './codesWithVideo.json'
cbStatements = require './cbStatements.json'

sessionLength = 80

lengths = {
    'TOCHI': sessionLength / 4, 
    'Paper': sessionLength / 4, 
    'Note': sessionLength / 8, 
    'SIG': sessionLength, 
    'casestudy': sessionLength / 4, 
    'panel': sessionLength,
    'altchi': sessionLength / 8,
    'special': sessionLength
}


days = {
        'day_1': {
                'type': 'day',
                'number': 1,
                'name': 'Monday',
                'timeslots': ['timeslot_1', 'timeslot_2', 'timeslot_3', 'timeslot_4'],
                'date': [2013, 4, 29]
            },
        'day_2': {
                'type': 'day',
                'number': 2,
                'name': 'Tuesday',
                'timeslots': ['timeslot_5', 'timeslot_6', 'timeslot_7', 'timeslot_8'],
                'date': [2013, 4, 30]
            },
        'day_3': {
                'type': 'day',
                'number': 3,
                'name': 'Wednesday',
                'timeslots': ['timeslot_10', 'timeslot_11', 'timeslot_12', 'timeslot_13'],
                'date': [2013, 5, 1]
            },
        'day_4': {
                'type': 'day',
                'number': 4,
                'name': 'Thursday',
                'timeslots': ['timeslot_14', 'timeslot_15', 'timeslot_16', 'timeslot_17'],
                'date': [2013, 5, 2]
            }
    }

timeslots = {}

for id, day of days
    timeslots[day.timeslots[0]] = {
        'type': 'timeslot',
        'number': 1,
        'name': 'Morning',
        'sessions': [],
        'start': [9, 0],            
        'end': [10, 20],
        'day': id
    }
    timeslots[day.timeslots[1]] = {
        'type': 'timeslot',
        'number': 2,
        'name': 'Before Lunch',
        'sessions': [],
        'start': [11, 0],
        'end': [12, 20],
        'day': id
    }
    timeslots[day.timeslots[2]] = {
        'type': 'timeslot',
        'number': 3,
        'name': 'After Lunch',
        'sessions': [],
        'start': [14, 0],
        'end': [15, 20],
        'day': id
    }
    timeslots[day.timeslots[3]] = {
        'type': 'timeslot',
        'number': 4,
        'name': 'Afternoon',
        'sessions': [],
        'start': [16, 0],
        'end': [17, 20],
        'day': id
    }


sessions = {}

for session in sessionData 
    sessionDoc = {}
    sessions[session.value._id] = sessionDoc
    sessionDoc.type = 'session'
    sessionDoc.venue = session.value.venue
    sessionDoc.title = session.value.title
    sessionDoc.tags = session.value.tags
    sessionDoc.communities = session.value.tags
    sessionDoc.personas = session.value.personas
    sessionDoc.tags = session.value.tags
    sessionDoc.communities = session.value.communities
    sessionDoc.submissions = session.value.content
    for sch in schedule
        if session.value.schedule == sch.id
            if letterCodes.code[sch.id]?
                sessionDoc.letterCode = letterCodes.code[sch.id]
            sessionDoc.room = sch.value.room
            sessionDoc.venue = sch.value.venue
    if session.value.timeslot? and session.value.timeslot.length > 0
        day = session.value.timeslot.split(' ')[0]
        start = session.value.timeslot.split(' ')[1].split('-')[0].split(':').map (val) -> parseInt val #Whoa!
        for id, dayValue of days
            if dayValue.name == day
                for timeslot in dayValue.timeslots
                    if timeslots[timeslot].start[0] == start[0]
                        sessionDoc.timeslot = timeslot
                        timeslots[timeslot].sessions.push session.value._id
sessions['sInteractivity'] = { 
    type: 'session',
    venue: 'interactivity',
    title: 'Interactivity',
    submissions: [],
    timeslot: 'always' 
}

submissions = {}

addSubmission = (submission) ->
    submissionValue = submission.value
    if submissionValue.authorKeywords?
        submissionValue.authorKeywords = submissionValue.authorKeywords.split(/[\n\t,;\\]+/).map (word) ->
            word.trim().toLowerCase().replace '.', ''
    if letterCodes.code[submissionValue._id]?
        submissionValue.letterCode = letterCodes.code[submissionValue._id]
    if submissionValue.letterCode? and _.contains(codesWithVideos, submissionValue.letterCode)
        submissionValue.hasVideo = true
    else
        submissionValue.hasVideo = false
    delete submissionValue._id
    delete submissionValue._rev
    if submissionValue.session?
        submissionValue.room = sessions[submissionValue.session].room
    else if submissionValue.sessions?
        submissionValue.room = sessions[submissionValue.sessions[0]].room

    if not submissionValue.cbStatement?
        if cbStatements[submissionValue.letterCode]?
            submissionValue.cbStatement =cbStatements[submissionValue.letterCode]

    institutions = []
    cities = []
    states = []
    countries = []
    if submissionValue.authorList?
        for author in submissionValue.authorList
            if author.primary?
                p = author.primary
                if p.institution? and not _.contains(institutions, p.institution)
                    institutions.push p.institution
                if p.city? and not _.contains(cities, p.city)
                    cities.push p.city
                if p.state? and not _.contains(states, p.state)
                    states.push p.state
                if p.country? and not _.contains(countries, p.country)
                    countries.push p.country
            if author.secondary?
                s = author.secondary
                if s.institution? and not _.contains(institutions, s.institution)
                    institutions.push s.institution
                if s.city? and not _.contains(cities, s.city)
                    cities.push s.city
                if s.state? and not _.contains(states, s.state)
                    states.push s.state
                if s.country? and not _.contains(countries, s.country)
                    countries.push s.country
        submissionValue.institutions = institutions
        submissionValue.cities  = cities
        submissionValue.states  = states
        submissionValue.countries  = countries
    
    submissions[submission.id] = submissionValue
    
for submission in submissionData
    addSubmission submission

computeTimeForSubmission = (id, submission) ->
    if submission.session?
        session = sessions[submission.session]
    else if submission.sessions? #Submission is multi-session, take start of first
        session = sessions[submission.sessions[0]]
    if not session? #This shouldn't happen
        return
    timeslot = timeslots[session.timeslot]
    day = days[timeslot.day]
    startArray = day.date.concat timeslot.start
    start = new Date startArray[0], startArray[1], startArray[2], startArray[3], startArray[4]
    t = 0
    if not submission.sessions?
        sessionDurations= []
        for s in session.submissions #We'll accumulate the time up to the given submission
            if submissions[s].venue == 'paper'
                duration = lengths[submissions[s].subtype] #Paper or Note
            else
                duration = lengths[submissions[s].venue]
            if id == s
                venue = submissions[s].venue
                break
            t += duration
        for s in session.submissions
            if submissions[s].venue == 'paper'
                duration = lengths[submissions[s].subtype] #Paper or Note
            else
                duration = lengths[submissions[s].venue]
            durationObj = {}
            durationObj.submission = s
            durationObj.duration = duration 
            sessionDurations.push durationObj
        submissionStart = new Date(start.getTime() + t * 60000)
        submission.startTime = [submissionStart.getFullYear(), submissionStart.getMonth(), submissionStart.getDate(), submissionStart.getHours(), submissionStart.getMinutes()]
        submission.duration = duration
        submission.sessionDurations = sessionDurations
    else #We are dealing with a multi-session submission
        submission.startTime = [start.getFullYear(), start.getMonth(), start.getDate(), start.getHours(), start.getMinutes()]
        submission.duration = submission.sessions.length * sessionLength
        durationObj = {}
        durationObj.submission = id
        durationObj.duration = sessionLength
        submission.sessionDurations = [durationObj]

for id, submission of submissions
    computeTimeForSubmission id, submission
    
for submission in interactivity
    submission.value.session = 'sInteractivity'
    submission.value.type = 'submission'
    sessions[submission.value.session].submissions.push submission.id
    addSubmission submission
    
insertInDb = (dict) ->
    for id, value of dict
       chidb.insert value, id, (err, body) ->
           if err?
               console.log err 

days['day_1'].timeslots.splice 0, 1
delete timeslots['timeslot_1']
days['day_4'].timeslots.splice 0, 1
delete timeslots['timeslot_14']
days['day_4'].timeslots.splice days['day_4'].timeslots.length - 1, days['day_4'].timeslots.length
delete timeslots['timeslot_17']

insertInDb days
insertInDb timeslots
insertInDb sessions            
insertInDb submissions