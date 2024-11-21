let mediaRecorder;
let audioChunks = [];

// Start recording
function startRecording() {
  audioChunks = [];
  navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
    mediaRecorder = new MediaRecorder(stream);
    mediaRecorder.ondataavailable = event => audioChunks.push(event.data);
    mediaRecorder.start();
  });
}

// Stop recording
function stopRecording() {
  return new Promise((resolve, reject) => {
    mediaRecorder.onstop = () => {
      const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
      resolve(audioBlob);
    };
    mediaRecorder.stop();
  });
}

async function sendAudioToServer() {
  try {
    const audioBlob = await stopRecording();
    const formData = new FormData();
    formData.append('file', audioBlob, 'recording.webm');

    const response = await fetch('http://127.0.0.1:5000/transcribe', {
      method: 'POST',
      body: formData
    });

    if (!response.ok) {
      throw new Error(`Server error: ${response.status}`);
    }

    const result = await response.json();
    console.log('Transcription:', result.transcription);

    // Return the transcription directly as a string
    return result.transcription;
  } catch (error) {
    console.error("Error sending audio:", error);
    return null;
  }
}



// Send audio to Flask server
//async function sendAudioToServer() {
//  try {
//    const audioBlob = await stopRecording();
//    const formData = new FormData();
//    formData.append('file', audioBlob, 'recording.webm');
//    // Send the recorded audio to the Flask server
//    const response = await fetch('http://127.0.0.1:5000/transcribe', {
//      method: 'POST',
//      body: formData
//    });
//
//    if (!response.ok) {
//      throw new Error(`Server error: ${response.status}`);
//    }
//
//    const result = await response.json();
//    console.log('Transcription: ->', result.transcription);
//    return result.transcription;
//  } catch (error) {
//    console.error("Error sending audio:", error);
//  }
//}

//async function sendAudioToServer() {
//  try {
//    const audioBlob = await stopRecording();
//    const formData = new FormData();
//    formData.append('file', audioBlob, 'recording.webm');
//    console.log('Audio : >',formData);
//    // Send the recorded audio to the Flask server
//    const response = await fetch('http://127.0.0.1:5000/transcribe', {
//      method: 'POST',
//      body: formData
//    });
//
//    if (!response.ok) {
//      throw new Error(`Server error: ${response.status}`);
//    }
//
//    const result = await response.json();
//    console.log('Transcription: ->', result.transcription);
//
//    // Return the transcription in a structure
//    return { 'transcription': result.transcription };
//  } catch (error) {
//    console.error("Error sending audio:", error);
//    // Return error structure
//    return { 'transcription': 'Error occurred' };
//  }
//}
