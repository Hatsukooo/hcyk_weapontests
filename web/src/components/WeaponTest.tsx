import React, { useState, useEffect } from "react";
import { useVisibility } from "../providers/VisibilityProvider";
import { fetchNui } from "../utils/fetchNui";
import { debugData } from "../utils/debugData";
import { isEnvBrowser } from "../utils/misc";
import "./WeaponTest.css";

const WeaponTest = () => {
 const { visible } = useVisibility();
 const [currentStep, setCurrentStep] = useState("start");
 const [allQuestions, setAllQuestions] = useState([]);
 const [testQuestions, setTestQuestions] = useState([]);
 const [loading, setLoading] = useState(true);
 const [error, setError] = useState(null);
 const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
 const [selectedAnswers, setSelectedAnswers] = useState({});
 const [results, setResults] = useState({ passed: false, score: 0, wrongAnswers: [] });
 const [timeLeft, setTimeLeft] = useState(60);
 const [testStarted, setTestStarted] = useState(false);
 const questionCount = 10; // Number of questions to include in each test

 // Helper to select random questions
 const selectRandomQuestions = (questions, count) => {
   if (!questions || questions.length === 0) return [];
   
   // First, create a shuffled copy of all questions
   const shuffledQuestions = [...questions].sort(() => Math.random() - 0.5);
   
   // Take the subset we need
   const selectedQuestions = questions.length <= count 
     ? shuffledQuestions 
     : shuffledQuestions.slice(0, count);
   
   // Now shuffle the options within each question
   return shuffleOptionsInQuestions(selectedQuestions);
 };

 // Helper to shuffle answer options within questions
 const shuffleOptionsInQuestions = (questions) => {
   return questions.map(question => {
     // Create pairs of options and their corresponding letter values
     const optionPairs = question.Question_options.map((option, index) => {
       return {
         text: option,
         letter: String.fromCharCode(97 + index) // 'a', 'b', 'c', 'd'
       };
     });
     
     // Store the correct answer text based on current letter
     const correctLetter = question.Answear;
     const correctOptionIndex = correctLetter.charCodeAt(0) - 97;
     const correctOptionText = question.Question_options[correctOptionIndex];
     
     // Shuffle the option pairs
     for (let i = optionPairs.length - 1; i > 0; i--) {
       const j = Math.floor(Math.random() * (i + 1));
       [optionPairs[i], optionPairs[j]] = [optionPairs[j], optionPairs[i]];
     }
     
     // Find the new position of the correct answer
     const newCorrectIndex = optionPairs.findIndex(pair => pair.text === correctOptionText);
     const newCorrectLetter = String.fromCharCode(97 + newCorrectIndex);
     
     // Return updated question with shuffled options
     return {
       ...question,
       Question_options: optionPairs.map(pair => pair.text),
       Answear: newCorrectLetter,
       // Store original data for reference if needed
       originalAnswear: correctLetter
     };
   });
 };

 // Mock data for browser development
 useEffect(() => {
   if (isEnvBrowser()) {
     console.log("Setting up mock data for browser development");
     // Create a larger set of mock questions
     const mockQuestions = [
       {
         Question_Label: "When you hold a weapon you cannot...",
         Question_options: ["Run", "Point it at civilians", "Reload", "Change weapons"],
         Answear: "b"
       },
       {
         Question_Label: "When can you fire a weapon?",
         Question_options: ["Anytime", "Only at the shooting range", "Only when threatened", "Only in self-defense"],
         Answear: "d"
       },
       {
         Question_Label: "How should you store a weapon when not in use?",
         Question_options: ["Loaded and ready", "In a safe place, unloaded", "Hidden under your car seat", "It doesn't matter"],
         Answear: "b"
       },
       {
         Question_Label: "What should you ALWAYS assume about a weapon?",
         Question_options: ["It's safe to handle", "It's loaded and ready to fire", "It's legal to carry", "It's expensive"],
         Answear: "b"
       },
       {
         Question_Label: "What is the first rule of weapon safety?",
         Question_options: ["Always keep your finger off the trigger until ready to shoot", "Always keep the weapon loaded", "Always know your target and what's beyond it", "Always keep the weapon pointed in a safe direction"],
         Answear: "d"
       },
       {
         Question_Label: "When is it appropriate to brandish your weapon in public?",
         Question_options: ["When you feel threatened", "When someone insults you", "Only when you intend to use it", "To show it off to friends"],
         Answear: "c"
       }
     ];
     
     console.log("Setting mock questions:", mockQuestions);
     setAllQuestions(mockQuestions);
     setLoading(false);
   }
 }, []);

 // Fetch questions when component mounts
 useEffect(() => {
   const getQuestionsData = async () => {
     try {
       console.log("Fetching questions from NUI...");
       setLoading(true);
       
       // For real implementation, we'll fetch from the NUI
       // For now, provide mock data as a fallback
       const response = await fetchNui("getQuestions", {}, {
         questions: [
           {
             Question_Label: "When you hold a weapon you cannot...",
             Question_options: ["Run", "Point it at civilians", "Reload", "Change weapons"],
             Answear: "b"
           },
           {
             Question_Label: "When can you fire a weapon?",
             Question_options: ["Anytime", "Only at the shooting range", "Only when threatened", "Only in self-defense"],
             Answear: "d"
           }
         ]
       });
       
       console.log("Questions response:", response);
       
       if (response && response.questions && Array.isArray(response.questions)) {
         setAllQuestions(response.questions);
         setLoading(false);
         setError(null);
       } else {
         console.error("Invalid questions format:", response);
         setError("Invalid questions data format");
         if (!isEnvBrowser()) {
           setLoading(false);
         }
       }
     } catch (error) {
       console.error("Error fetching questions:", error);
       setError("Failed to load questions: " + error.message);
       if (!isEnvBrowser()) {
         setLoading(false);
       }
     }
   };

   if (visible && !isEnvBrowser()) {
     getQuestionsData();
   }
 }, [visible]);

 // Timer for each question
 useEffect(() => {
   if (testStarted && currentStep === "test") {
     const timer = setInterval(() => {
       setTimeLeft((prev) => {
         if (prev <= 1) {
           clearInterval(timer);
           handleNextQuestion();
           return 60;
         }
         return prev - 1;
       });
     }, 1000);

     return () => clearInterval(timer);
   }
 }, [testStarted, currentStep, currentQuestionIndex]);

 const startTest = () => {
   if (allQuestions.length === 0) {
     console.error("Cannot start test: No questions available");
     return;
   }
   
   // Select and shuffle questions for the test
   const selected = selectRandomQuestions(allQuestions, questionCount);
   setTestQuestions(selected);
   
   setCurrentStep("test");
   setTestStarted(true);
   setCurrentQuestionIndex(0);
   setSelectedAnswers({});
   setTimeLeft(60);
 };

 const handleSelectAnswer = (questionIndex, answer) => {
   setSelectedAnswers({
     ...selectedAnswers,
     [questionIndex]: answer,
   });
 };

 const handleNextQuestion = () => {
   if (currentQuestionIndex < testQuestions.length - 1) {
     setCurrentQuestionIndex(currentQuestionIndex + 1);
     setTimeLeft(60);
   } else {
     // Calculate results
     const wrongAnswers = [];
     let correctCount = 0;

     testQuestions.forEach((question, index) => {
       const userAnswer = selectedAnswers[index];
       if (userAnswer === question.Answear) {
         correctCount++;
       } else {
         wrongAnswers.push({
           question: question.Question_Label,
           userAnswer: userAnswer || "No answer",
           correctAnswer: question.Answear,
           options: question.Question_options
         });
       }
     });

     const score = (correctCount / testQuestions.length) * 100;
     const passed = score >= 75; // Assuming 75% is passing score

     setResults({
       passed,
       score,
       wrongAnswers,
     });

     // Send results to server
     console.log("Test completed:", { passed, score, wrongAnswers });
     fetchNui("submitTest", {
       passed,
       score,
       wrongAnswers,
     });

     setCurrentStep("results");
     setTestStarted(false);
   }
 };

 const handleRestartTest = () => {
   setCurrentStep("start");
 };

 const getOptionText = (question, optionKey) => {
   if (!question) return "Unknown option";
   const optionIndex = optionKey.charCodeAt(0) - 97; // Convert 'a' to 0, 'b' to 1, etc.
   return question.Question_options[optionIndex] || "Unknown option";
 };

 const renderProgressBar = () => {
   const progress = ((currentQuestionIndex + 1) / testQuestions.length) * 100;
   
   return (
     <div className="progress-container">
       <div className="progress-bar" style={{ width: `${progress}%` }}></div>
     </div>
   );
 };

 const renderCurrentQuestion = () => {
   if (loading) {
     return <div className="loading">Loading questions...</div>;
   }

   if (error) {
     return <div className="error">Error: {error}</div>;
   }

   if (!testQuestions || testQuestions.length === 0) {
     return <div className="error">No questions available.</div>;
   }

   if (currentQuestionIndex >= testQuestions.length) {
     return <div className="error">Question index out of bounds.</div>;
   }

   const question = testQuestions[currentQuestionIndex];
   
   return (
     <div className="question-container">
       <div className="question-header">
         {renderProgressBar()}
         <span className="question-number">Question {currentQuestionIndex + 1} of {testQuestions.length}</span>
         <span className="timer">Time left: {timeLeft} seconds</span>
       </div>
       
       <div className="question-content">
         <h2>{question.Question_Label}</h2>
         
         <div className="options-container">
           {question.Question_options.map((option, index) => {
             const optionKey = String.fromCharCode(97 + index); // Convert 0->a, 1->b, etc.
             return (
               <div 
                 key={index} 
                 className={`option ${selectedAnswers[currentQuestionIndex] === optionKey ? 'selected' : ''}`}
                 onClick={() => handleSelectAnswer(currentQuestionIndex, optionKey)}
               >
                 <div className="option-letter">{optionKey.toUpperCase()}</div>
                 <div className="option-text">{option}</div>
               </div>
             );
           })}
         </div>
       </div>

       <div className="navigation-buttons">
         <button className="next-button" onClick={handleNextQuestion}>
           {currentQuestionIndex < testQuestions.length - 1 ? 'Next Question' : 'Finish Test'}
         </button>
       </div>
     </div>
   );
 };

 const renderStartScreen = () => {
   if (loading) {
     return <div className="loading">Loading questions...</div>;
   }

   if (error) {
     return <div className="error">Error: {error}</div>;
   }

   return (
     <div className="start-screen">
       <h1>Weapon License Test</h1>
       <p>This test will evaluate your knowledge of weapon safety and regulations.</p>
       <p>You must score at least 75% to pass and receive your weapon license.</p>
       <div className="test-details">
         <div className="detail-item">
           <span className="detail-icon">🕒</span>
           <span className="detail-text">60 seconds per question</span>
         </div>
         <div className="detail-item">
           <span className="detail-icon">📝</span>
           <span className="detail-text">{questionCount} multiple choice questions</span>
         </div>
         <div className="detail-item">
           <span className="detail-icon">🎯</span>
           <span className="detail-text">75% passing score required</span>
         </div>
       </div>
       <button className="start-button" onClick={startTest} disabled={allQuestions.length === 0}>
         Start Test
       </button>
     </div>
   );
 };

 const renderResultsScreen = () => {
   // Calculate the circle's properties for the progress ring
   const circleRadius = 94;
   const circumference = 2 * Math.PI * circleRadius;
   const progressOffset = circumference - (results.score / 100) * circumference;
   
   return (
     <div className="results-screen">
       <h1 className={`results-header ${results.passed ? 'passed' : 'failed'}`}>
         {results.passed ? 'CONGRATULATIONS! YOU PASSED!' : 'TEST FAILED'}
       </h1>
       
       <div className={`score-display ${results.passed ? 'passed' : 'failed'}`}>
         <div className="score-circle">
           <svg className="progress-ring" width="200" height="200">
             <circle
               className="progress-ring__circle"
               stroke={results.passed ? "var(--success-color)" : "var(--error-color)"}
               strokeDasharray={circumference}
               strokeDashoffset={progressOffset}
               fill="transparent"
               r={circleRadius}
               cx="100"
               cy="100"
             />
           </svg>
           <span className="score-number">{Math.round(results.score)}%</span>
         </div>
         <p className="score-text">Your Score</p>
       </div>
       
       {results.passed ? (
         <div className="success-message">
           <p>You have successfully completed the Weapon License Test.</p>
           <p>Your license will be issued shortly.</p>
         </div>
       ) : (
         <div className="failure-message">
           <p>You didn't pass the test. Review the material and try again.</p>
           {results.wrongAnswers.length > 0 && (
             <div className="wrong-answers">
               <h3>Questions to Review:</h3>
               <ul>
                 {results.wrongAnswers.map((item, index) => (
                   <li key={index}>
                     <p className="review-question"><strong>{item.question}</strong></p>
                     <p className="review-answer">
                       Your answer: {item.userAnswer.toUpperCase()} - {getOptionText(
                         testQuestions.find(q => q.Question_Label === item.question),
                         item.userAnswer
                       )}
                     </p>
                     <p className="review-answer correct-answer">
                       Correct answer: {item.correctAnswer.toUpperCase()} - {getOptionText(
                         testQuestions.find(q => q.Question_Label === item.question),
                         item.correctAnswer
                       )}
                     </p>
                   </li>
                 ))}
               </ul>
             </div>
           )}
         </div>
       )}
       
       <button className="restart-button" onClick={handleRestartTest}>
         {results.passed ? 'CLOSE' : 'TRY AGAIN'}
       </button>
     </div>
   );
 };

 // Main render function - the test is now unclosable until finished
 return (
   <div className="weapon-test-ui">
     {currentStep === "start" && renderStartScreen()}
     {currentStep === "test" && renderCurrentQuestion()}
     {currentStep === "results" && renderResultsScreen()}
   </div>
 );
};

export default WeaponTest;