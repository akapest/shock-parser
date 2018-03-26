const electron = require('electron')

const app = electron.app

const BrowserWindow = electron.BrowserWindow

if (process.env.NODE_ENV === 'development') {
    require('electron-reload')(__dirname)
}

let mainWindow

function createWindow () {
    // Create the browser window.
    mainWindow = new BrowserWindow({width: 800, height: 600, icon: './cpu.png'})

    if (process.env.NODE_ENV === 'development') {
        mainWindow.loadURL(`http://localhost:3000`)
    } else {
        mainWindow.loadURL(`file://${__dirname}/index.html`)
    }

    // if (process.env.NODE_ENV === 'development') {
    //     mainWindow.webContents.openDevTools()
    // }

    mainWindow.on('closed', function () {
        mainWindow = null
    })
}

app.on('ready', createWindow)

app.on('window-all-closed', function () {
    // On OS X it is common for applications and their menu bar
    if (process.platform !== 'darwin') {
        app.quit()
    }
})

app.on('activate', function () {
    if (mainWindow === null) {
        createWindow()
    }
})

require('electron-context-menu')({
	// prepend: (params, browserWindow) => [{
     //    id: 'back',
     //    label: 'Back',
     //    click: () => { mainWindow.webContents.goBack() } // https://github.com/electron/electron/blob/master/docs/api/web-contents.md
	// },{
     //    id: 'home',
     //    label: 'Home',
     //    click: () => { mainWindow.webContents.goToIndex(0) }
	// },{
     //    id: 'forward',
     //    label: 'Forward',
     //    click: () => { mainWindow.webContents.goForward() }
	// }]
});
