import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/comment_model.dart';
import 'package:ibex_app/core/services/comment_service.dart';
import 'package:ibex_app/core/utils/helpers.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:provider/provider.dart';

class CommentSectionWidget extends StatefulWidget {
  final String classId;
  final String? postId;
  final String? classworkId;

  const CommentSectionWidget({
    super.key,
    required this.classId,
    this.postId,
    this.classworkId,
  }) : assert(postId != null || classworkId != null,
            'Must provide either postId or classworkId');

  @override
  State<CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  final _commentService = CommentService();
  final _commentController = TextEditingController();

  StreamSubscription<List<CommentModel>>? _subscription;
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() => _isLoading = true);
    final stream = widget.postId != null
        ? _commentService.streamPostComments(widget.postId!)
        : _commentService.streamClassworkComments(widget.classworkId!);

    _subscription = stream.listen(
      (comments) {
        if (mounted) {
          setState(() {
            _comments = comments;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await _commentService.addComment(
        classId: widget.classId,
        postId: widget.postId,
        classworkId: widget.classworkId,
        content: content,
        parentId: _replyingToId,
      );
      if (mounted) {
        _commentController.clear();
        setState(() {
          _replyingToId = null;
          _replyingToName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteComment(String id) async {
    try {
      await _commentService.deleteComment(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment')),
        );
      }
    }
  }

  void _setReplyContext(CommentModel parent) {
    setState(() {
      _replyingToId = parent.id;
      _replyingToName = parent.userName;
    });
    // Focus the text field via a focus node if we had one
  }

  void _cancelReplyContext() {
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthGate>();
    final currentUserId = auth.currentUser?.id;
    final isTeacher = auth.currentUser?.role == AppConstants.roleTeacher;

    // Group comments into threads
    final rootComments = _comments.where((c) => c.parentId == null).toList();
    final replies = _comments.where((c) => c.parentId != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          // Comments List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rootComments.length,
            itemBuilder: (context, index) {
              final comment = rootComments[index];
              final threadReplies =
                  replies.where((r) => r.parentId == comment.id).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CommentCard(
                    comment: comment,
                    canDelete:
                        isTeacher || currentUserId == comment.userId,
                    onDelete: () => _deleteComment(comment.id),
                    onReply: () => _setReplyContext(comment),
                  ),
                  if (threadReplies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, top: 4.0),
                      child: Column(
                        children: threadReplies.map((reply) {
                          return _CommentCard(
                            comment: reply,
                            canDelete: isTeacher ||
                                currentUserId == reply.userId,
                            onDelete: () => _deleteComment(reply.id),
                            isReply: true,
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          
          // Reply Context Banner
          if (_replyingToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppConstants.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingToName ?? 'someone'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReplyContext,
                    child: const Icon(Icons.close,
                        size: 16, color: AppConstants.primary),
                  ),
                ],
              ),
            ),
            
          // Input Field
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add class comment...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isSubmitting
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _submitComment,
                      icon: const Icon(Icons.send, color: AppConstants.primary),
                      splashRadius: 24,
                    ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final CommentModel comment;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final bool isReply;

  const _CommentCard({
    required this.comment,
    this.canDelete = false,
    this.onDelete,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 12 : 16,
            backgroundImage: comment.userPic != null
                ? NetworkImage(comment.userPic!)
                : null,
            backgroundColor: AppConstants.primary.withValues(alpha: 0.2),
            child: comment.userPic == null
                ? Text(
                    Helpers.getInitials(comment.userName),
                    style: TextStyle(
                      fontSize: isReply ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isReply ? AppConstants.primary.withValues(alpha: 0.1) : AppConstants.surfaceLight,
                border: isReply ? Border.all(color: AppConstants.primary.withValues(alpha: 0.2)) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          comment.userName ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isReply ? AppConstants.primary : AppConstants.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (comment.createdAt != null)
                        Text(
                          Helpers.timeAgo(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: isReply ? AppConstants.textPrimary : AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (onReply != null && !isReply)
                        GestureDetector(
                          onTap: onReply,
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ),
                      if (canDelete) ...[
                        if (onReply != null && !isReply)
                          const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
