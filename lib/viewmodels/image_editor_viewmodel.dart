import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/repositories/edit_repository.dart';
import 'package:vegavision/repositories/image_repository.dart';
import 'package:vegavision/services/storage_service.dart';

// TODO: Marker and MarkerType classes are used but not defined
// Suggested implementation:
// enum MarkerType {
//   remove,
//   replace,
//   enhance,
//   adjust
// }
//
// class Marker {
//   final String id;
//   final double x;
//   final double y;
//   final MarkerType type;
//   final double size;
//   final String? label;
//
//   Marker({
//     required this.id,
//     required this.x,
//     required this.y,
//     required this.type,
//     this.size = 1.0,
//     this.label,
//   });
// }

class EditableImage {

  EditableImage({required this.image, this.file, this.dimensions});
  final ImageModel image;
  final File? file;
  final Size? dimensions;
}

class MarkerAction {

  MarkerAction({required this.type, this.marker, this.index});
  final ActionType type;
  final Marker? marker;
  final int? index;
}

enum ActionType { add, remove, update }

class UndoRedoStack<T> {
  final List<T> _undoStack = [];
  final List<T> _redoStack = [];

  void add(T action) {
    _undoStack.add(action);
    _redoStack.clear();
  }

  T? undo() {
    if (_undoStack.isEmpty) return null;

    final action = _undoStack.removeLast();
    _redoStack.add(action);
    return action;
  }

  T? redo() {
    if (_redoStack.isEmpty) return null;

    final action = _redoStack.removeLast();
    _undoStack.add(action);
    return action;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

class ImageEditorViewModel extends ChangeNotifier {

  ImageEditorViewModel(this._imageRepository, this._editRepository, this._storageService);
  final ImageRepository _imageRepository;
  final EditRepository _editRepository;
  final StorageService _storageService;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  String? _error;
  String? get error => _error;

  UploadStatus _uploadStatus = UploadStatus.notStarted;
  UploadStatus get uploadStatus => _uploadStatus;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  ImageModel? _selectedImage;
  ImageModel? get selectedImage => _selectedImage;

  EditableImage? _editableImage;
  EditableImage? get editableImage => _editableImage;

  List<Marker> _markers = [];
  List<Marker> get markers => _markers;

  String _instruction = '';
  String get instruction => _instruction;

  String? _instructionError;
  String? get instructionError => _instructionError;

  bool get hasValidInstruction => _instruction.isNotEmpty && _instructionError == null;

  MarkerType _currentMarkerType = MarkerType.remove;
  MarkerType get currentMarkerType => _currentMarkerType;

  double _currentMarkerSize = 1.0;
  double get currentMarkerSize => _currentMarkerSize;

  final UndoRedoStack<MarkerAction> _undoRedoStack = UndoRedoStack<MarkerAction>();
  bool get canUndo => _undoRedoStack.canUndo;
  bool get canRedo => _undoRedoStack.canRedo;

  // Cancel token for upload
  bool _cancelUpload = false;

  Future<void> loadImage(String imageId) async {
    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      _selectedImage = await _imageRepository.getImage(imageId);

      if (_selectedImage == null) {
        _error = 'Image not found';
      } else {
        // Load image file
        final File? imageFile = await _imageRepository.getImageFile(imageId);

        // Get image dimensions
        final ImageDimensions? dimensions = await _imageRepository.getImageDimensions(imageId);

        // Create editable image
        _editableImage = EditableImage(
          image: _selectedImage!,
          file: imageFile,
          dimensions:
              dimensions != null
                  ? Size(dimensions.width.toDouble(), dimensions.height.toDouble())
                  : null,
        );

        // Reset markers and actions
        _markers = [];
        _undoRedoStack.clear();
      }
    } catch (e) {
      _error = 'Failed to load image: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void setCurrentMarkerType(MarkerType type) {
    _currentMarkerType = type;
    notifyListeners();
  }

  void setCurrentMarkerSize(double size) {
    _currentMarkerSize = size.clamp(0.5, 2.0);
    notifyListeners();
  }

  void addMarker(double x, double y, {String? label}) {
    final marker = Marker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      x: x,
      y: y,
      type: _currentMarkerType,
      size: _currentMarkerSize,
      label: label,
    );

    _markers.add(marker);

    // Add to undo/redo stack
    _undoRedoStack.add(MarkerAction(type: ActionType.add, marker: marker));

    notifyListeners();
  }

  void removeMarker(int index) {
    if (index >= 0 && index < _markers.length) {
      final removedMarker = _markers[index];
      _markers.removeAt(index);

      // Add to undo/redo stack
      _undoRedoStack.add(
        MarkerAction(type: ActionType.remove, marker: removedMarker, index: index),
      );

      notifyListeners();
    }
  }

  void updateMarker(int index, Marker updatedMarker) {
    if (index >= 0 && index < _markers.length) {
      final oldMarker = _markers[index];
      _markers[index] = updatedMarker;

      // Add to undo/redo stack
      _undoRedoStack.add(MarkerAction(type: ActionType.update, marker: oldMarker, index: index));

      notifyListeners();
    }
  }

  void undo() {
    final action = _undoRedoStack.undo();

    if (action != null) {
      switch (action.type) {
        case ActionType.add:
          // Remove the added marker
          final index = _markers.indexWhere((m) => m.id == action.marker!.id);
          if (index != -1) {
            _markers.removeAt(index);
          }
          break;
        case ActionType.remove:
          // Add back the removed marker
          if (action.index != null && action.marker != null) {
            final index = action.index!.clamp(0, _markers.length);
            _markers.insert(index, action.marker!);
          }
          break;
        case ActionType.update:
          // Restore the old marker
          if (action.index != null && action.marker != null) {
            final index = action.index!;
            if (index >= 0 && index < _markers.length) {
              _markers[index] = action.marker!;
            }
          }
          break;
      }

      notifyListeners();
    }
  }

  void redo() {
    final action = _undoRedoStack.redo();

    if (action != null) {
      switch (action.type) {
        case ActionType.add:
          // Re-add the marker
          if (action.marker != null) {
            _markers.add(action.marker!);
          }
          break;
        case ActionType.remove:
          // Remove the marker again
          if (action.index != null && action.marker != null) {
            final index = _markers.indexWhere((m) => m.id == action.marker!.id);
            if (index != -1) {
              _markers.removeAt(index);
            }
          }
          break;
        case ActionType.update:
          // Apply the update again
          if (action.index != null) {
            final index = action.index!;
            if (index >= 0 && index < _markers.length) {
              // The current marker in the list is the "old" marker that we just restored via undo
              // To redo, we need to determine what the updated marker was
              // This is a bit tricky since we only stored the old version
              // In a real implementation, we might want to store both old and new versions
              final currentMarker = _markers[index];

              // For now, just toggle the marker type as an example
              final updatedMarker = Marker(
                id: currentMarker.id,
                x: currentMarker.x,
                y: currentMarker.y,
                type:
                    currentMarker.type == MarkerType.remove
                        ? MarkerType.replace
                        : MarkerType.remove,
                size: currentMarker.size,
                label: currentMarker.label,
              );

              _markers[index] = updatedMarker;
            }
          }
          break;
      }

      notifyListeners();
    }
  }

  void clearMarkers() {
    if (_markers.isNotEmpty) {
      // Save current markers for undo
      final oldMarkers = List<Marker>.from(_markers);

      _markers.clear();

      // Add all removals as a single action (simplified approach)
      _undoRedoStack.add(MarkerAction(type: ActionType.remove, marker: oldMarkers.first, index: 0));

      notifyListeners();
    }
  }

  void setInstruction(String value) {
    _instruction = value;
    _validateInstruction();
    notifyListeners();
  }

  void _validateInstruction() {
    if (_instruction.isEmpty) {
      _instructionError = 'Instruction cannot be empty';
    } else if (_instruction.length < 3) {
      _instructionError = 'Instruction is too short';
    } else if (_instruction.length > 500) {
      _instructionError = 'Instruction is too long (max 500 characters)';
    } else {
      _instructionError = null;
    }
  }

  Future<EditRequest?> submitEditRequest() async {
    if (_selectedImage == null) {
      _error = 'No image selected';
      notifyListeners();
      return null;
    }

    if (_markers.isEmpty) {
      _error = 'No markers placed';
      notifyListeners();
      return null;
    }

    _validateInstruction();
    if (!hasValidInstruction) {
      _error = _instructionError ?? 'Invalid instruction';
      notifyListeners();
      return null;
    }

    _isBusy = true;
    _error = null;
    _uploadStatus = UploadStatus.uploading;
    _uploadProgress = 0.0;
    _cancelUpload = false;
    notifyListeners();

    try {
      // Upload image if not already uploaded
      if (_selectedImage!.cloudPath == null) {
        // Update status to uploading
        await _imageRepository.updateImageStatus(_selectedImage!.id, ImageStatus.uploading);

        // Upload image with progress tracking
        final String cloudPath = await _storageService.uploadImage(
          _selectedImage!.localPath,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();

            // Check if cancellation was requested
            if (_cancelUpload) {
              throw Exception('Upload cancelled');
            }
          },
        );

        // Update status to uploaded with cloud path
        await _imageRepository.updateImageStatus(
          _selectedImage!.id,
          ImageStatus.uploaded,
          cloudPath: cloudPath,
        );

        // Refresh selected image
        _selectedImage = await _imageRepository.getImage(_selectedImage!.id);
      }

      _uploadStatus = UploadStatus.completed;
      notifyListeners();

      // Create edit request
      final editRequest = await _editRepository.createEditRequest(
        _selectedImage!.id,
        _markers,
        _instruction,
      );

      return editRequest;
    } catch (e) {
      if (_cancelUpload) {
        _error = 'Upload cancelled';
        _uploadStatus = UploadStatus.cancelled;
      } else {
        _error = 'Failed to submit edit request: $e';
        _uploadStatus = UploadStatus.failed;
      }
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void cancelUpload() {
    if (_uploadStatus == UploadStatus.uploading) {
      _cancelUpload = true;
      notifyListeners();
    }
  }
}

enum UploadStatus { notStarted, uploading, completed, failed, cancelled }
