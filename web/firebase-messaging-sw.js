importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
 apiKey: "AIzaSyBJjT_sOocqcpp5jesX4XP5O3j8q14oxps",
   authDomain: "level-up-19583.firebaseapp.com",
   projectId: "level-up-19583",
   storageBucket: "level-up-19583.firebasestorage.app",
   messagingSenderId: "219751000005",
   appId: "1:219751000005:web:10ca4484de8149e53f0dac"
});

const messaging = firebase.messaging();