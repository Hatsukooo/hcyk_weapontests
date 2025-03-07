import React, { useState, useEffect } from "react";
import { useVisibility } from "../providers/VisibilityProvider";
import { fetchNui } from "../utils/fetchNui";
import "./WeaponTest.css";

const WeaponTest = () => {
  const { visible } = useVisibility();
  const [currentStep, setCurrentStep] = useState("start"); // start, test, results
  const [questions, setQuestions] = useState([]);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [selectedAnswers, setSelectedAnswers] = useState({});
  const [results, setResults] = useState({ passed: false, score: 0, wrongAnswers: [] });
  const [timeLeft, setTimeLeft] = useState(60); // 60 seconds per question
  const [testStarted, setTestStarted] = useState(false);

  // Fetch questions when component mounts
  useEffect(() => {
    if (visible) {
      fetchNui("getQuestions").then((data) => {
        if (data && data.questions) {
          setQuestions(data.questions);
        }
      });
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
    if (currentQuestionIndex < questions.length - 1) {
      setCurrentQuestionIndex(currentQuestionIndex + 1);
      setTimeLeft(60);
    } else {
      // Calculate results
      const wrongAnswers = [];
      let correctCount = 0;

      questions.forEach((question, index) => {
        if (selectedAnswers[index] === question.Answear) {
          correctCount++;
        } else {
          wrongAnswers.push({
            question: question.Question_Label,
            userAnswer: selectedAnswers[index] || "No answer",
            correctAnswer: question.Answear,
          });
        }
      });

      const score = (correctCount / questions.length) * 100;
      const passed = score >= 75; // Assuming 75% is passing score

      setResults({
        passed,
        score,
        wrongAnswers,
      });

      // Send results to server
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

  const renderCurrentQuestion = () => {
    if (!questions || questions.length === 0 || currentQuestionIndex >= questions.length) {
      return <div className="loading">Loading questions...</div>;
    }

    const question = questions[currentQuestionIndex];
    
    return (
      <div className="question-container">
        <div className="question-header">
          <span className="question-number">Question {currentQuestionIndex + 1} of {questions.length}</span>
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
            {currentQuestionIndex < questions.length - 1 ? 'Next Question' : 'Finish Test'}
          </button>
        </div>
      </div>
    );
  };

  const renderStartScreen = () => (
    <div className="start-screen">
      <div className="logo">
        <img src="https://via.placeholder.com/150" alt="Weapon License Test Logo" />
      </div>
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
          <span className="detail-text">{questions.length} multiple choice questions</span>
        </div>
        <div className="detail-item">
          <span className="detail-icon">🎯</span>
          <span className="detail-text">75% passing score required</span>
        </div>
      </div>
      <button className="start-button" onClick={startTest}>Start Test</button>
    </div>
  );

  const renderResultsScreen = () => (
    <div className="results-screen">
      <h1 className={`results-header ${results.passed ? 'passed' : 'failed'}`}>
        {results.passed ? 'Congratulations! You Passed!' : 'Test Failed'}
      </h1>
      
      <div className="score-display">
        <div className="score-circle">
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
                    <p><strong>{item.question}</strong></p>
                    <p>Your answer: {item.userAnswer}</p>
                    <p>Correct answer: {item.correctAnswer}</p>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}
      
      <button className="restart-button" onClick={handleRestartTest}>
        {results.passed ? 'Return to Menu' : 'Try Again'}
      </button>
    </div>
  );

  // Main render function
  return (
    <div className="weapon-test-ui">
      {currentStep === "start" && renderStartScreen()}
      {currentStep === "test" && renderCurrentQuestion()}
      {currentStep === "results" && renderResultsScreen()}
    </div>
  );
};

export default WeaponTest;