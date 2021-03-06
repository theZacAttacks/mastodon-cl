(in-package :mastodon.api)

(defparameter *strip-html-tags* t
  "Set this to nil to have MAKE-STATUS not strip html tags out of the content of a message")

(defvar *status-privacy-modes* '(:public :unlisted :private :direct)
  "the different privacy modes that a status can have")

(defclass status ()
  ((content :initarg  :content
	    :reader status-content)
   (author  :initarg  :author
	    :reader status-author)
   (reblogger :initarg :reblogger
	      :reader status-reblogger)
   (visibility :initarg :visibility
	       :reader status-visibility)
   (id      :initarg :id
	    :reader status-id)
   (created-at :initarg :created-at
	       :reader status-posted-at)
   (tags    :initarg :tags
	    :reader status-tags)
   (reblog-count :initarg :reblog-count
		 :reader status-times-reblogged)
   (favourite-count :initarg :fave-count
		    :reader status-times-favourited)
   (mentions :initarg :mentions
	     :reader status-mentions)
   (nsfw     :initarg :nsfw
	     :reader status-nsfw?)
   (cw       :initarg :cw
	     :reader status-cw)
   (reblogged :initarg :reblogged
	      :reader status-reblogged?)
   (favourited :initarg :faved
	       :reader status-favourited?)
   (reply-id :initarg :reply-id
	     :reader status-reply-id)
   (url :initarg :url
	:reader status-url)
   (uri :initarg :uri
	:reader status-uri)))

(defun make-status (raw-status)
  (let ((reblog (rest (assoc :reblog raw-status))))
    (if reblog (setq raw-status (append reblog `((:reblogger . ,(cdr (assoc :account raw-status)))))))
    (if (not (null raw-status))
	(make-instance 'status
		       :id (cdr (assoc :id raw-status))
		       :content (if *strip-html-tags*
				    (remove-html-tags (cdr (assoc :content raw-status)))
				    (cdr (assoc :content raw-status)))
		       :author (make-account (cdr (assoc :account raw-status)))
		       :reblogger (make-account (cdr (assoc :reblogger raw-status)))
		       :visibility (cdr (assoc :visibility raw-status))
		       :cw (cdr (assoc :spoiler--text raw-status))
		       :created-at (cdr (assoc :created--at raw-status))
		       :reply-id (cdr (assoc :in--reply--to--id raw-status))
		       :mentions (cdr (assoc :mentions raw-status))
		       :url (cdr (assoc :url raw-status))
		       :uri (cdr (assoc :uri raw-status))
		       :nsfw (cdr (assoc :sensitive raw-status))
		       :faved (cdr (assoc :favourited raw-status))
		       :reblogged (cdr (assoc :reblogged raw-status))
		       :reblog-count (cdr (assoc :reblogs--count raw-status))
		       :fave-count (cdr (assoc :favourites--count raw-status))
		       :tags (labels ((make-tag-list (tags)
					(if (cdr tags)
					    (cons (format nil "#~a" (cdr (assoc :name (car tags)))) (make-tag-list (rest tags)))
					    (cons (format nil "#~a" (cdr (assoc :name (car tags)))) nil))))
			       (when (not (null (cdr (assoc :tags raw-status))))
				 (make-tag-list (cdr (assoc :tags raw-status))))))
      nil)))

(defmethod print-object ((obj status) out)
  (if (not (null (status-reblogger obj)))
      (format out "~&~a Reblogged by:~a~%~a"
	      (status-author obj) (status-reblogger obj)
	      (status-content obj))
      (format out "~&~a~%~a" (status-author obj) (status-content obj))))

(defmethod status-toggle-favourite ((toot status))
  (if (status-favourited? toot)
      (status-unfavourite toot)
      (status-favourite toot)))

(defmethod status-toggle-reblog ((toot status))
  (if (status-reblogged? toot)
      (status-unreblog toot)
      (status-reblog toot)))

(defmethod status-unfavourite ((toot status))
  (unfave-status (status-id toot))
  (setf (slot-value toot 'favourited) nil))

(defmethod status-favourite ((toot status))
  (fave-status (status-id toot))
  (setf (slot-value toot 'favourited) t))

(defmethod status-reblog ((toot status))
  (reblog-status (status-id toot))
  (setf (slot-value toot 'reblogged) t))

(defmethod status-unreblog ((toot status))
  (unreblog-status (status-id toot))
  (setf (slot-value toot 'reblogged) nil))

(defmethod status-delete ((toot status))
  (delete-status (status-id toot))
  (status-id toot))

(defmethod status-get-context ((toot status))
  (let ((context (get-context (status-id toot))))
    (labels ((make-statuses (s-list)
	       (if (cdr s-list)
		   (cons (make-status (car s-list)) (make-statuses (rest s-list)))
		   (cons (make-status (car s-list)) nil))))
      `((:ancestors . ,(make-statuses (cdr (assoc :ancestors context))))
	(:descendents . ,(make-statuses (cdr (assoc :descendents context))))))))

(defun get-status (id)
  (make-status
   (decode-json-from-string
    (masto--perform-request `(:get ,(concatenate 'string
						"statuses/" id))))))

(defun fave-status (id)
  (masto--perform-request `(:post ,(concatenate 'string
					       "statuses/"
					       id
					       "/favourite"))))

(defun unfave-status (id)
  (masto--perform-request `(:post ,(concatenate 'string
					       "statuses/"
					       id
					       "/unfavourite"))))

(defun reblog-status (id)
  (masto--perform-request `(:post ,(concatenate 'string
					       "statuses/"
					       id
					       "/reblog"))))

(defun unreblog-status (id)
  (masto--perform-request `(:post ,(concatenate 'string
					       "statuses/"
					       id
					       "/unreblog"))))
(defun pin-status (id)
  (masto--perform-request `(:post ,(concatenate 'string
					       "statuses/"
					       id
					       "/pin"))))

(defun unpin-status (id)
  (masto--perform-request `(:post ,(concatenate 'string
					       "statuses/"
					       id
					       "/unpin"))))
    
(defun delete-status (id)
  (masto--perform-request `(:delete ,(concatenate 'string "statuses/" id))))

(defun get-context (id)
  (decode-json-from-string
   (masto--perform-request `(:get ,(concatenate 'string
					       "statuses/" id "/context")))))

(defun get-reblogged (id &key max-id since-id (limit 40))
  (setq limit (write-to-string (min limit 80)))
  (decode-json-from-string
   (masto--perform-request `(:get
			    ,(concatenate 'string
					  "statuses/" id "/reblogged_by"
					  "?limit=" (write-to-string limit)
					  (if max-id (concatenate 'string "&max_id=" max-id))
					  (if since-id (concatenate 'string "&since_id=" since-id)))))))

(defun get-favourited (id &key max-id since-id (limit 40))
  (setq limit (write-to-string (min limit 80)))
  (decode-json-from-string
   (masto--perform-request `(:get
			    ,(concatenate 'string
					  "statuses/" id "/favourited_by"
					  "?limit=" (write-to-string limit)
					  (if max-id (concatenate 'string "&max_id=" max-id))
					  (if since-id (concatenate 'string "&since_id=" since-id)))))))

(defun mute-conversation (id)
  (masto--perform-request `(:post
			   ,(concatenate 'string
					 "statuses/" id "/mute"))))

(defun unmute-conversation (id)
  (masto--perform-request `(:post
			   ,(concatenate 'string
					 "statuses/" id "/unmute"))))

(defun get-favourited-statuses (&key max-id since-id (limit 20))
  (setq limit (write-to-string (min limit 40)))
  (decode-json-from-string
   (masto--perform-request `(:get
			    ,(concatenate 'string
					  "favourites"
					  "?limit=" (write-to-string limit)
					  (if max-id (concatenate 'string "&max_id=" max-id))
					  (if since-id (concatenate 'string "&since_id=" since-id)))))))

(defun post-status (status &key (visibility :public) nsfw cw reply-id media)
  (when (not (member visibility *status-privacy-modes* :test #'string=)) (error 'unrecognized-status-privacy))
  (make-status
   (decode-json-from-string
    (masto--perform-request `(:post "statuses" :content
				 ,(concatenate 'list
					       `(("status" . ,status)
						 ("visibility" . ,(string-downcase (string visibility)))
						 ("spoiler_text" . ,cw)
						 ("sensitive" . ,(and nsfw "true"))
						 ("in_reply_to_id" . ,reply-id))
					       (mass-upload-media media)))))))
