"use client"

import { useToast } from "@/hooks/use-toast"
import { Toast, ToastTitle, ToastDescription } from "@/components/ui/toast"

export function Toaster() {
  const { toasts } = useToast()

  return (
    <div className="fixed top-0 z-[100] flex max-h-screen w-full flex-col-reverse p-4 sm:right-0 sm:top-auto sm:bottom-0 sm:flex-col md:max-w-[420px]">
      {toasts.map(({ id, title, description, action, variant, onClose, ...props }) => (
        <Toast key={id} variant={variant} onClose={onClose} {...props}>
          <div className="grid gap-1">
            {title && <ToastTitle>{title}</ToastTitle>}
            {description && <ToastDescription>{description}</ToastDescription>}
          </div>
          {action}
        </Toast>
      ))}
    </div>
  )
}