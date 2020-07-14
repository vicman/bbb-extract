# bbb-extract
Extract the event.xml file after meeting


### Requirements
- inotify-tools (check change files) https://github.com/inotify-tools/inotify-tools/wiki
- supervisor http://supervisord.org/

###  Install
```sh
apt-get install inotify-tools
apt-get install supervisor
```

assign permission to file watch.sh
```sh
chmod 755 /home/user/watch.sh
```

Start supervisor
```sh
systemctl start supervisor
```

Config watcher in supervidor
http://supervisord.org/configuration.html

Example
```sh
 cd /etc/supervisor/conf.d
 touch watch.conf
 ```

```sh
[program:meeting_watch]
command=/home/user/watch.sh
autostart=true
autorestart=true
killasgroup=true
stopsignal=KILL
stderr_logfile=/var/log/supervisor/meeting_watch.err.log
stdout_logfile=/var/log/supervisor/meeting_watch.out.log
 ```

```sh
supervisorctl reread
supervisorctl update
 ```
###  Example PHP 
```php
 /**
     * Evento llamado al procesar un video
     * @param Request $request
     */
    public function receiveEvents(Request $request){
        
        Log::info("End Video " . pprint_r($request->all(),false));
        if (false == $request->hasFile('data')){
            echo "No se envió ningun archivo";
            die();
        }
        
        
        
        $internal_id   = $request->input('internal_id');
        //validar si el evento existe y ya fue procesado
        $event = Event::where('internal_id',$internal_id)->first();
        if (empty($event)){
            echo "Not found";
             die();
        }
        
        $file    = $request->file('data');        
        $path    = storage_path() . "/app/{$internal_id}/";
        
        $rs = Storage::put($internal_id . '/'  . $file->getClientOriginalName(),file_get_contents($file));
        if (false == $rs){
            Log::error("No se pudo procesar el archivo " . pprint_r($request->all(),false));
            echo "No se pudo procesar el archivo";
            die();
        }
        
        $zip = new \ZipArchive;
        $res = $zip->open($path . $file->getClientOriginalName());
        if ($res === true) {
            $zip->extractTo($path);
            $zip->close();
            
            if (file_exists($path . 'events.xml')){
                @unlink($path . $file->getClientOriginalName()); //elimina el zip
                
                //lee el xml
                $this->synchronizeRepository->processEvents($event, $path . 'events.xml');
                echo 'ok';
            }else{
                echo 'file cant be uncompress';
            }
        } else {
            echo 'failed res=' . $res;
        }
        die();
    }
   ``` 
