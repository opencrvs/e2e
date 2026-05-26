import prompts, { PromptObject } from 'prompts'
import {
    Secret,
    Variable
} from './github'

export type Question<T extends string> = PromptObject<T> & {
  name: T
  valueType?: 'SECRET' | 'VARIABLE'
  scope: 'ENVIRONMENT' | 'REPOSITORY'
  valueLabel?: string
}

export type QuestionDescriptor<T extends string> = Omit<Question<T>, 'type'> & {
  type: 'disabled' | PromptObject<T>['type']
}

export type SecretAnswer = {
  type: 'SECRET'
  scope: 'ENVIRONMENT' | 'REPOSITORY'
  name: string
  value: string
  didExist: Secret | undefined
}

export type VariableAnswer = {
  type: 'VARIABLE'
  name: string
  didExist: Variable | undefined
  value: string
  scope: 'ENVIRONMENT' | 'REPOSITORY'
}

export type Answer = SecretAnswer | VariableAnswer
export type Answers = Answer[]
export type AnswerWithNullValue =
  | (Omit<SecretAnswer, 'value'> & {
      value: SecretAnswer['value'] | null
    })
  | (Omit<VariableAnswer, 'value'> & {
      value: VariableAnswer['value'] | null
    })
