(hs.ipc.cliInstall) ; ensure CLI installed

(local fennel (require :fennel))
(local extensions (require :extensions))
(require :lib.globals)
(local {:contains? contains?
        :for-each  for-each
        :map       map
        :merge     merge
        :reduce    reduce
        :split     split
        :some      some} (require :lib.functional))
(local atom (require :lib.atom))
(require-macros :lib.macros)
(require-macros :lib.advice.macros)

;; Add compatability with spoons as the spoon global may not exist at
;; this point until a spoon is loaded. It will exist if a spoon is
;; loaded from init.lua

(global spoon (or _G.spoon {}))

;; Make ~/.spacehammer folder override repo files
(local homedir (os.getenv "HOME"))
(local customdir (.. homedir "/.spacehammer"))
(tset fennel :path (.. customdir "/?.fnl;" fennel.path))

(local elogger (require :elogger))
(local elog (elogger.new "core.fnl" "debug"))

(local log (hs.logger.new "\tcore.fnl\t" "debug"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; defaults
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(set hs.hints.style :vimperator)
(set hs.hints.showTitleThresh 4)
(set hs.hints.titleMaxSize 10)
(set hs.hints.fontSize 30)
(set hs.window.animationDuration 0.2)

"
alert :: str, { style }, seconds -> nil
Shortcut for showing an alert on the primary screen for a specified duration
Takes a message string, a style table, and the number of seconds to show alert
Returns nil. This function causes side-effects.
"
(global fw hs.window.focusedWindow)

(global alert
        (afn
         alert
         [str style seconds]
         "
         Global alert function used for spacehammer modals and reload
         alerts after config reloads
         "
         (hs.alert.show str
                        style
                        nil
                        seconds)))

(global pprint (fn [x] (print (fennel.view x))))

(global get-config
        (afn get-config
          []
          "
          Returns the global config object, or error if called early
          "
          (error "get-config can only be called after all modules have initialized")))
(global windows-list [])

(fn file-exists?
  [filepath]
  "
  Determine if a file exists and is readable.
  Takes a file path string
  Returns true if file is readable
  "
  (let [file (io.open filepath "r")]
    (when file
      (io.close file))
    (~= file nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create custom config file if it doesn't exist
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn copy-file
  [source dest]
  "
  Copies the contents of a source file to a destination file.
  Takes a source file path and a destination file path.
  Returns nil
  "
  (let [default-config (io.open source "r")
        custom-config (io.open dest "a")]
    (each [line _ (: default-config :lines)]
      (: custom-config :write (.. line "\n")))
    (: custom-config :close)
    (: default-config :close)))

;; If ~/.spacehammer/config.fnl does not exist
;; - Create ~/.spacehammer dir
;; - Copy default ~/.hammerspoon/config.example.fnl to ~/.spacehammer/config.fnl
(let [example-path (.. hs.configdir "/config.example.fnl")
      target-path (.. customdir "/config.fnl")]
  (when (not (file-exists? target-path))
    (log.d (.. "Copying " example-path " to " target-path))
    (hs.fs.mkdir customdir)
    (copy-file example-path target-path)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto reload config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn source-filename?
  [file]
  "
  Determine if a file is not an emacs backup file which starts with \".#\"
  Takes a file path string
  Returns true if it's a source file and not an emacs backup file.
  "
  (not (string.match file ".#")))

(fn source-extension?
  [file]
  "
  Determine if a file is a .fnl or .lua file
  Takes a file string
  Returns true if file extension ends in .fnl or .lua
  "
  (let [ext (split "%p" file)]
    (and
     (or (contains? "fnl" ext)
         (contains? "lua" ext))
     (not (string.match file "-test%..*$")))))


(fn source-updated?
  [file]
  "
  Determine if a file is a valid source file that we can load
  Takes a file string path
  Returns true if file is not an emacs backup and is a .fnl or .lua type.
  "
  (and (source-filename? file)
       (source-extension? file)))

(fn config-reloader
  [files]
  "
  If the list of files contains some hammerspoon or spacehammer source files:
  reload hammerspoon
  Takes a list of files from our config file watcher.
  Performs side effect of reloading hammerspoon.
  Returns nil
  "
  (when (some source-updated? files)
    (hs.console.clearConsole)
    (hs.reload)
  )
 )

(fn get-info
  [cw]
  (
    (log.d (.. "***** get-info ********"))
    ; (let [ app (: cw :application)
    ;        pid (.. "\"" (: app :pid) "\"")
    ; ;       title       (.. "\"" (: current-app :title) "\"")
    ; ;       screen      (.. "\"" (: (hs.screen.mainscreen) :id) "\"")]
    ;        win (: app :mainwindow)
    ;        frame (: win :frame)
    ;        {:_x x :_y y} frame
    ;        coords  {:x (+ x 100) :y (+ y 100)}]
    ;     (when cw
    ;         (log.f "### app pid : [%s]" (: app :pid))
    ;         (log.w "### window info : " cw)
    ;     )
    ; )
  )
)

(fn change-before-focused
    []
    (log.d (.. "**** chchange-before-focused *********"))
  (let [current-win (-> (hs.window.focusedWindow) )
        app (: current-win :application)
        win (: app :mainWindow)
        frame (: win :frame)
        {:_x x :_y y} frame
        coords  {:x (+ x 100) :y (+ y 100)}]
    ; (let [current-win (-> (hs.window.focusedwindow))
    ; ;       pid         (.. "\"" (: current-app :pid) "\"")
    ; ;       title       (.. "\"" (: current-app :title) "\"")
    ; ;       screen      (.. "\"" (: (hs.screen.mainscreen) :id) "\"")]
    ;         app (: current-win :application)
    ;         win (: app :mainwindow)
    ;         frame (: win :frame)
    ;         {:_x x :_y y} frame
    ;         coords  {:x (+ x 100) :y (+ y 100)}]
        (when app
            ; (get-info current-win)
            (table.insert windows-list current-win)
            (log.f "### app pid : [%s]" (: app :pid))
            ; (log.w "### app pid : " current-win)
            (log.f "### windows count : [%d]" (length windows-list ))
            ; (log.w "### window focuesed app info: [%s]" (hs.inspect app))
            (log.wf "### window focuesed app info: [%s]"
                (hs.inspect app))
            (hs.reload)
        )
    )

)


(hs.hotkey.bind
  [:ctrl :cmd] "/" nil
  (fn []
      (change-before-focused)
      (log.d (.. "************** ::: bind"))
      (->> windows-list
        (map (fn [win]
            (
             (get-info win)
             (log.w "### app pid : " (: win :application :pid))
            ))
        )
      )
      (log.f "### windows count : [%d]" (length windows-list ))
  )
)

(fn watch-files
  [dir]
  "
  Watches hammerspoon or spacehammer source files. When a file updates we reload
  hammerspoon.
  Takes a directory to watch.
  Returns a function to stop the watcher.
  "
  (let [watcher (hs.pathwatcher.new dir config-reloader)]
    (: watcher :start)
    (fn []
      (: watcher :stop))))

;; Create a global config-files-watcher. Calling it stops the default watcher
(global config-files-watcher (watch-files hs.configdir))

(when (file-exists? (.. customdir "/config.fnl"))
  (global custom-files-watcher (watch-files customdir)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set utility keybindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; toggle hs.console with Ctrl+Cmd+~
(hs.hotkey.bind
 [:ctrl :cmd] "`" nil
 (fn []
   (if-let
    [console (hs.console.hswindow)]
    (when (= console (hs.console.hswindow))
      (hs.closeConsole))
    (hs.openConsole))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Load custom init.fnl file (if it exists)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(let [custom-init-file (.. customdir "/init.fnl")]
  (when (file-exists? custom-init-file)
    (fennel.dofile custom-init-file)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize core modules
;; - Requires each module
;; - Calls module.init and provides config.fnl table
;; - Stores global reference to all initialized resources to prevent garbage
;;   collection.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local config (require :config))

;; Initialize our modules that depend on config
(local modules [:lib.hyper
                :vim
                :windows
                :apps
                :lib.bind
                :lib.modal
                :lib.apps])

(defadvice get-config-impl
           []
           :override get-config
           "Returns global config obj"
           config)

;; Create a global reference so services like hs.application.watcher
;; do not get garbage collected.
(global resources
        (->> modules
             (map (fn [path]
                    (let [module (require path)]
                      {path (module.init config)})))
             (reduce #(merge $1 $2) {})))

