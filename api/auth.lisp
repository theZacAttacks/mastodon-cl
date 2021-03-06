(in-package :mastodon.api)

(defparameter *access-token* nil
  "currently loaded access token")

(defparameter *refresh-token* nil
  "currently loaded refresh token")

(defparameter *config-dir* "../config/"
  "path to where the tokens are saved")


(defun set-config-dir (new-dir)
  (ensure-directories-exist new-dir)
  (setq *config-dir* new-dir))

(defun load-tokens-for-user (username &key config-dir instance)
  (when config-dir (set-config-dir config-dir))
  (when instance (set-instance instance))
  (let ((config (load-config (concatenate 'string
					  (replace-all *instance* "https://" "")
					  ".conf"))))
    (block setting-tokens
      (dolist (tokens config)
	(setq *client-id* (cdr (assoc :id tokens)))
	(setq *client-key* (cdr (assoc :client-key tokens)))
	(setq *client-secret* (cdr (assoc :client-secret tokens)))
	(dolist (login (cdr (assoc :logins tokens)))
	  (when (string= (cdr (assoc :username login))
			 username)
	    (progn 
	      (setq *access-token* (cdr (assoc :access-token login)))
	      (setq *refresh-token* (cdr (assoc :refresh-token login)))
	      (return-from setting-tokens))))))))

(defun oauth-login (&key instance (redirect-uri "urn:ietf:wg:oauth:2.0:oob") (scopes (list "read"))
		      (method :authorize-code))
  (unless (and *client-secret* *client-key*)
    (error 'api-error :reason "the client key and secret have not been set. Have you created an app yet?"))
  (when instance (set-instance instance))

  (if (not *refresh-token*)
      (format nil "Please visit this URL to get your code: ~a"
	      (masto--api-path (concatenate 'string
					   "oauth/authorize"
					   "?response_type=code"
					   (format nil "&scope=~{~a~^%20~}" scopes)
					   (format nil "&client_id=~a" *client-key*)
					   (format nil "&redirect_uri=~a" redirect-uri))))
      (let ((response (decode-json-from-string
		       (masto--perform-request `(:post "oauth/token" :content
						      (("grant_type" . "authorization_code")
						       ("scope" . ,(format nil "~{~a~^ ~}" scopes))
						       ("redirect_uri" . ,redirect-uri)
						       ("client_id" . ,*client-key*)
						       ("client_secret" . ,*client-secret*)
						       ("code" . ,*refresh-token*)))))))
	(setq *access-token* (cdr (assoc :access--token response))))))


(defun console-oauth-login (&key instance (redirect-uri "urn:ietf:wg:oauth:2.0:oob") (scopes (list "read")))
  (let ((url (oauth-login :instance instance
			  :redirect-uri redirect-uri
			  :scopes scopes)))
    (if (not (cdr (assoc :access--token url)))
	(progn
	  (print (format nil "~a~%" url))
	  (setq *refresh-token* (string-downcase (string-trim '(#\Space #\Newline #\Tab) (read))))
	  (oauth-login :instance instance
		       :redirect-uri redirect-uri
		       :scopes scopes)))))
  

(defun login (user-email password &key (save-token t) instance (scopes '("read")))
  "tries to log in to *INSTANCE* with the provided USER-EMAIL and PASSWORD
if SAVE-TOKEN is non-nil the tokens will be written out to a config file"
  (unless (and *client-secret* *client-key*)
    (error 'api-error :reason "the client key and secret have not been set. Have you created an app yet?"))
  
  (when instance (set-instance instance))
  
  (let ((token (decode-json-from-string
		(masto--perform-request `(:post "oauth/token" :content
					       (("client_id" . ,*client-key*)
						("client_secret" . ,*client-secret*)
						("grant_type" . "password")
						("username" . ,user-email)
						("scope" . ,(format nil "~{~a~^ ~}" scopes))
						("password" . ,password)))))))
    (setq *access-token* (cdr (assoc :access--token token)))
    (when save-token
      (write-access-tokens :username (account-username (verify-credentials))))))
