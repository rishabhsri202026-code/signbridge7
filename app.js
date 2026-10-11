(() => {
  const $ = id => document.getElementById(id);
  const video = $("camera");
  let stream = null, recorder = null, chunks = [], recordingTimer = null;
  const bridge = "http://127.0.0.1:8765";
  const setMessage = (text, kind = "") => { $("message").textContent = text; $("message").className = "message " + kind; };
  async function checkBridge() {
    try {
      const res = await fetch(bridge + "/health", {cache:"no-store"});
      const data = await res.json();
      if (data.model_loaded) {
        $("modelStatus").textContent = "Model connected";
        $("modelStatus").className = "status good";
        setMessage("Sanket model is loaded. Start the camera to test a clip.", "good");
      } else {
        $("modelStatus").textContent = "Model not loaded";
        $("modelStatus").className = "status bad";
        setMessage("Bridge found, but the model is not loaded. Check the Sanket terminal and /health endpoint.", "warn");
      }
    } catch {
      $("modelStatus").textContent = "Bridge offline";
      $("modelStatus").className = "status bad";
      setMessage("Sanket bridge is not reachable. Start it on this same device, then refresh.", "warn");
    }
  }
  async function startCamera() {
    try {
      if (!navigator.mediaDevices?.getUserMedia) throw new Error("Camera API unavailable. Open this page over HTTPS or localhost.");
      stream = await navigator.mediaDevices.getUserMedia({video:{facingMode:"user"},audio:false});
      video.srcObject = stream;
      $("cameraPlaceholder").classList.add("hidden");
      $("cameraStatus").textContent = "Camera ready";
      $("startCamera").disabled = true; $("stopCamera").disabled = false; $("translate").disabled = false;
      setMessage("Camera is ready. The model bridge is checked separately.", "");
    } catch (e) { setMessage("Camera error: " + e.message + " Check browser permission and use HTTPS or localhost.", "warn"); }
  }
  function stopCamera() {
    if (recordingTimer) clearTimeout(recordingTimer);
    if (recorder && recorder.state !== "inactive") recorder.stop();
    if (stream) stream.getTracks().forEach(t => t.stop());
    stream = null; video.srcObject = null;
    $("cameraPlaceholder").classList.remove("hidden");
    $("cameraStatus").textContent = "Camera off";
    $("startCamera").disabled = false; $("stopCamera").disabled = true; $("translate").disabled = true;
    $("recordingFlag").classList.add("hidden");
  }
  async function recordAndTranslate() {
    if (!stream || !window.MediaRecorder) { setMessage("Camera or MediaRecorder is unavailable in this browser.", "warn"); return; }
    $("translate").disabled = true; $("startCamera").disabled = true;
    chunks = [];
    const mime = ["video/webm;codecs=vp9","video/webm;codecs=vp8","video/webm"].find(t => MediaRecorder.isTypeSupported(t));
    try { recorder = new MediaRecorder(stream, mime ? {mimeType:mime} : undefined); }
    catch (e) { setMessage("Could not start video recording: " + e.message, "warn"); $("translate").disabled = false; return; }
    recorder.ondataavailable = e => { if (e.data && e.data.size) chunks.push(e.data); };
    recorder.onerror = e => { setMessage("Recording failed: " + (e.error?.message || "unknown error"), "warn"); };
    recorder.onstop = async () => {
      $("recordingFlag").classList.add("hidden");
      const blob = new Blob(chunks, {type:recorder.mimeType || "video/webm"});
      if (!blob.size) { setMessage("No video data recorded. Try again.", "warn"); finish(); return; }
      setMessage("Sending clip to Sanket model… this may take a while on CPU.");
      try {
        const res = await fetch(bridge + "/translate", {method:"POST",headers:{"Content-Type":blob.type || "video/webm"},body:blob});
        const data = await res.json();
        if (!res.ok || !data.ok) throw new Error(data.error || "Translation request failed.");
        const text = $("mode").value === "direct" ? (data.raw || "No words predicted.") : (data.sentence || data.raw || "No words predicted.");
        $("output").textContent = text;
        $("rawOutput").textContent = data.raw || "No raw gloss returned.";
        $("speak").disabled = !data.raw && !data.sentence;
        $("copy").disabled = !text;
        setMessage("Clip processed. " + (data.chunks ?? 0) + " chunk(s); results may be inaccurate.", "good");
      } catch (e) { setMessage("Translation failed: " + e.message + ". Check the bridge terminal.", "warn"); }
      finally { finish(); }
    };
    recorder.start(); $("recordingFlag").classList.remove("hidden"); setMessage("Recording for 5 seconds. Sign clearly and keep your hands in frame.");
    recordingTimer = setTimeout(() => { recordingTimer = null; if (recorder && recorder.state !== "inactive") recorder.stop(); }, 5000);
  }
  function finish() { $("translate").disabled = !stream; $("startCamera").disabled = !!stream; }
  $("startCamera").addEventListener("click", startCamera);
  $("stopCamera").addEventListener("click", stopCamera);
  $("translate").addEventListener("click", recordAndTranslate);
  $("speak").addEventListener("click", () => { const t = $("output").textContent; if (t && "speechSynthesis" in window) { speechSynthesis.cancel(); speechSynthesis.speak(new SpeechSynthesisUtterance(t)); } });
  $("copy").addEventListener("click", async () => { try { await navigator.clipboard.writeText($("output").textContent); setMessage("Translation copied.", "good"); } catch { setMessage("Clipboard permission was blocked by the browser.", "warn"); } });
  window.addEventListener("beforeunload", () => { if (stream) stream.getTracks().forEach(t => t.stop()); });
  if ("serviceWorker" in navigator && (location.protocol === "https:" || location.hostname === "localhost")) window.addEventListener("load", () => navigator.serviceWorker.register("./sw.js").catch(() => {}));
  checkBridge();
  setInterval(checkBridge, 15000);
})();