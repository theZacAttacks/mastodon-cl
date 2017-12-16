(in-package :mastodon.api)

(defvar *status-privacy-modes* '("public" "unlisted" "private" "direct")
  "the different privacy modes that a status can have")

(defclass status ()
  ((content :initarg  :content
	    :accessor status-content)
   (author  :initarg  :author
	    :accessor status-author)
   (visibility :initarg :visibility
	       :accessor status-visibility)
   (id      :initarg :id
	    :accessor status-id)
   (created-at :initarg :created-at
	       :accessor status-posted-at)
   (tags    :initarg :tags
	    :accessor status-tags)
   (reblog-count :accessor status-times-reblogged)
   (favourite-count :accessor status-times-faved)
   (mentions :initarg :mentions
	     :accessor status-mentions)
   (nsfw     :initarg :nsfw
	     :accessor status-nsfw?)
   (cw       :initarg :cw
	     :accessor status-cw)
   (reblogged :initarg :reblogged
	      :accessor status-reblogged?)
   (favourited :initarg :faved
	       :accessor status-favourited?)
   (reply-id :initarg :reply-id
	     :accessor status-reply-id)
   (url :initarg :url
	:accessor status-url)))

(defun make-status (raw-status)
  (make-instance 'status
		 :id (cdr (assoc :id raw-status))
		 :content (cdr (assoc :content raw-status))
		 :author (make-account (cdr (assoc :account raw-status)))
		 :visibility (cdr (assoc :visibility raw-status))
		 :cw (cdr (assoc :spoiler--text raw-status))
		 :created-at (cdr (assoc :created--at raw-status))
		 :reply-id (cdr (assoc :in--reply--to--id raw-status))
		 :mentions (cdr (assoc :mentions raw-status))
		 :url (cdr (assoc :url raw-status))
		 :nsfw (cdr (assoc :sensitive raw-status))
		 :faved (cdr (assoc :favourited raw-status))
		 :reblogged (cdr (assoc :reblogged raw-status))))

;(defmethod status-times-reblogged (toot status)
;    )

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

(defun get-reblog-count (id &key max-id since-id (limit 40))
  (setq limit (min limit 80))
  (decode-json-from-string
   (masto--perform-request `(:get
			    ,(concatenate 'string
					  "statuses/" id "/reblogged_by"
					  "?limit=" (write-to-string limit)
					  (if max-id (concatenate 'string "&max_id=" max-id))
					  (if since-id (concatenate 'string "&since_id=" since-id)))))))

(defun get-favourite-count (id &key max-id since-id (limit 40))
  (setq limit (min limit 80))
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
  (setq limit (min limit 40))
  (decode-json-from-string
   (masto--perform-request `(:get
			    ,(concatenate 'string
					  "favourites"
					  "?limit=" (write-to-string limit)
					  (if max-id (concatenate 'string "&max_id=" max-id))
					  (if since-id (concatenate 'string "&since_id=" since-id)))))))

(defun post-status (status &key (visibility "public") nsfw cw reply-id media)
  (when (not (member visibility *status-privacy-modes* :test #'string=)) (error 'unrecognized-status-privacy))
  (masto--perform-request `(:post "statuses" :content
				 ,(concatenate 'list
					       `(("status" . ,status)
						 ("visibility" . ,visibility)
						 ("spoiler_text" . ,cw)
						 ("sensitive" . ,(and nsfw "true"))
						 ("in_reply_to_id" . ,reply-id))
					       (mass-upload-media media)))))
