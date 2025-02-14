const assert = require('assert');
const Request = require("request");
//todo: implement queued jobs
module.exports = {
    pausejob: (cancelobj) => {
        cancelobj=JSON.parse(cancelobj)
        console.log("cancelcommand received id: " + cancelobj.id)
        console.log(buildApiUrl(global.config.STATIC_START_JOB_URL) + cancelobj.id)
        console.log(cancelobj.body)
        Request({ url: buildApiUrl(global.config.STATIC_START_JOB_URL) + cancelobj.id, method: 'PUT', json: cancelobj.body}, function(error, response, body){ 
            if (error){
                global.socketio.emit("error", "Error pauseing job, "+ error);
                console.log("Pause command error: "+ error)
            }else{
             global.socketio.emit("msg", body);
                console.log("Pause command OK:" + body);
            }
        });
        return;
    },
    multiply: (x, y) => {
        return x * y;
    },
    //delete job by _id int array, called from client using socket.io
    deletejob: (id_array_string) => {
        id_array=JSON.parse(id_array_string);
        console.log("Deleting job array:");
        console.log(id_array_string)
        global.db.jobs.find({ _id: { $in: id_array }}).exec( function(err,cursor){
                      console.log("Found Job to delete:" + cursor.length )
                        // Set an existing field's value
                         global.db.jobs.update({ _id: { $in: id_array } }, { $set: { deleted: true } }, { multi: true }, function (err, numReplaced) {
                            if (err){
                                console.log("Error deleting job from DB: " + err);
                            }
                            console.log("Deleted " +numReplaced + " Jobs from DB")
                        });

        })
        return;
    },
    
    //delete all jobs, called from client using socket.io
    deletealljobs: () => {
        console.log("Purging all jobs from DB due to user request")
        global.db.jobs.find({}).exec( function(err,cursor){
                      console.log("Found Job to delete:" + cursor.length )
                      global.db.jobs.update({}, { $set: { deleted: true } }, { multi: true }, function (err, numReplaced) {
                            if (err){
                                console.log("Error deleting job from DB: " + err);
                            }
                            console.log("Deleted " +numReplaced + " Jobs from DB")
                        })
        })
        return;
    }
    
};

function buildApiUrl(what){
    return "http://" + global.config.STATIC_API_HOST + ":" +  global.config.STATIC_API_PORT + what;  
}


