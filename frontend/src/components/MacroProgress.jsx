import React from 'react'

export default function MacroProgress({ label, current, goal, color }) {
  const percentage = Math.min((current / goal) * 100, 100)

  const colorClasses = {
    blue: 'bg-blue-500',
    green: 'bg-green-500',
    orange: 'bg-orange-500',
    purple: 'bg-purple-500',
  }

  const textColorClasses = {
    blue: 'text-blue-600',
    green: 'text-green-600',
    orange: 'text-orange-600',
    purple: 'text-purple-600',
  }

  return (
    <div className="w-full">
      <div className="flex justify-between items-center mb-2">
        <label className="text-sm font-semibold text-gray-700">{label}</label>
        <span className={`text-sm font-bold ${textColorClasses[color] || 'text-blue-600'}`}>
          {current.toFixed(1)} / {goal}
        </span>
      </div>

      <div className="progress-bar-container">
        <div
          className={`progress-bar-fill ${colorClasses[color] || 'bg-blue-500'}`}
          style={{ width: `${percentage}%` }}
        />
      </div>

      <div className="text-xs text-gray-500 mt-1">
        {percentage.toFixed(0)}% of daily goal
      </div>
    </div>
  )
}
