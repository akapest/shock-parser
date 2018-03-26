module.exports  = {

    messaging:
        message: 'Hallo {{username}}'
        dryRun: true
        cycleDelay: 2000 # delay after cycle, should be greater then fetching.requestDelay so messaging is working continiously

    table:
        itemsPerPage: 25

    fetching:
        maxPage: 1
#        maxDepth: {startOf: 'month', which: 'previous'}
        userLastOnlineDaysAgo: 30
        requestDelay: 1000

    wgg:
        requestDelay: 1000

    WGG:
        requestDelay: 1000

    WGS:
        requestDelay: 1000
        defaultUser:
            username: 'konstpestov@gmail.com'
            password: 'DkZMpLKbt2UH'

    wgs:
        maxPage: 1
        requestDelay: 1000
        defaultUser:
            username: 'konstpestov@gmail.com'
            password: 'DkZMpLKbt2UH'

}