"use client"

import * as React from "react"

interface Toast {
  id: string
  title?: string
  description?: string
  action?: React.ReactNode
  variant?: "default" | "destructive" | "success"
  onClose?: () => void
}

interface ToastState {
  toasts: Toast[]
}

const initialState: ToastState = {
  toasts: []
}

type ToastAction = 
  | { type: "ADD_TOAST"; toast: Toast }
  | { type: "UPDATE_TOAST"; toast: Partial<Toast> & Pick<Toast, "id"> }
  | { type: "DISMISS_TOAST"; toastId?: string }
  | { type: "REMOVE_TOAST"; toastId?: string }

function toastReducer(state: ToastState, action: ToastAction): ToastState {
  switch (action.type) {
    case "ADD_TOAST":
      return {
        ...state,
        toasts: [action.toast, ...state.toasts]
      }
    case "UPDATE_TOAST":
      return {
        ...state,
        toasts: state.toasts.map((t) =>
          t.id === action.toast.id ? { ...t, ...action.toast } : t
        )
      }
    case "DISMISS_TOAST": {
      const { toastId } = action
      if (toastId) {
        return {
          ...state,
          toasts: state.toasts.filter((t) => t.id !== toastId)
        }
      } else {
        return {
          ...state,
          toasts: []
        }
      }
    }
    case "REMOVE_TOAST":
      if (action.toastId === undefined) {
        return {
          ...state,
          toasts: []
        }
      }
      return {
        ...state,
        toasts: state.toasts.filter((t) => t.id !== action.toastId)
      }
  }
}

const ToastContext = React.createContext<{
  toast: (props: Omit<Toast, "id">) => { id: string; dismiss: () => void }
  dismiss: (toastId?: string) => void
  toasts: Toast[]
} | null>(null)

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = React.useReducer(toastReducer, initialState)

  React.useEffect(() => {
    const timeouts = new Map<string, NodeJS.Timeout>()

    state.toasts.forEach((toast) => {
      if (!timeouts.has(toast.id)) {
        const timeout = setTimeout(() => {
          dispatch({ type: "REMOVE_TOAST", toastId: toast.id })
        }, 5000)
        timeouts.set(toast.id, timeout)
      }
    })

    return () => {
      timeouts.forEach((timeout) => clearTimeout(timeout))
    }
  }, [state.toasts])

  const toast = React.useCallback(
    (props: Omit<Toast, "id">) => {
      const id = Math.random().toString(36).substr(2, 9)
      const newToast: Toast = {
        ...props,
        id,
        onClose: () => dispatch({ type: "DISMISS_TOAST", toastId: id })
      }

      dispatch({ type: "ADD_TOAST", toast: newToast })

      return {
        id,
        dismiss: () => dispatch({ type: "DISMISS_TOAST", toastId: id })
      }
    },
    []
  )

  const dismiss = React.useCallback((toastId?: string) => {
    dispatch({ type: "DISMISS_TOAST", toastId })
  }, [])

  return (
    <ToastContext.Provider value={{ toast, dismiss, toasts: state.toasts }}>
      {children}
    </ToastContext.Provider>
  )
}

export function useToast() {
  const context = React.useContext(ToastContext)
  if (!context) {
    throw new Error("useToast must be used within a ToastProvider")
  }
  return context
}

export type { Toast }