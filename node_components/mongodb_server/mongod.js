const os = require("os")
const path = require("path");
const fs = require("fs");
const { spawn } = require("child_process");

class Mongod {
    
    constructor(dbpath) {
        this.#dbpath = dbpath;
        if (!dbpath){
            throw new Error("You must pass dbpath paramter to Class constructor");
        }
    }

    //callbacks - called by childprocess "on" events
    onStdErr = function(){};
    onStdOut = function(){};
    onExit   = function(){};
    onError  = function(){};
    
    //public fields readonly
    isRunning   = false;
    lastPid     = -1;
    childProcess = null;
    binaryFull  = null;

    //public fields read/write (change before calling start)
    binaryPath  = os.tmpdir();   //where mongod binary will be extracted to. Can be changed before calling start method
    port        = 27017;

    //private fields
    #dbpath = "";   //private field, initialized by start

    async stop(){
        if (this.childProcess){
            this.childProcess.kill('SIGINT');
        }
    }

    /* starts the database process */
    async start() {
            this.binaryFull = await dumpBinaryToDisk(this.binaryPath);
            this.childProcess = spawn(this.binaryFull, ["--dbpath",this.#dbpath,"--port",this.port],{cwd: this.binaryPath});
            this.lastPid = this.childProcess.pid;
            this.isRunning = true;
            // listen for errors as they may prevent the exit event from firing

            this.childProcess.stdout.on('data', this.onStdOut);
            this.childProcess.stderr.on('data', this.onStdErr);
            this.childProcess.on('error', this.onExit);
            this.childProcess.on('exit', this.internal_process_exit); 
    }

    internal_process_exit(code){
        this.isRunning = false;
        this.childProcess = null;
        this.lastPid = -1;
        this.onExit(code);
    }
}

/* Writes binary from internally stored base64 to os temp path */
async function dumpBinaryToDisk(where){

    var full = path.join(where,"mongod.exe");
    //todo: decide os here and deliver more choices of binaries with package
    var b64 = require("./bin/mongod_w64.js").getBase64();
    let buff = Buffer.from(b64, 'base64');
    await fs.writeFileSync(full, buff);
    return full;
}

module.exports = Mongod;