<?php
class GitUpdate extends MX_Controller {

    public $repoPath = '/opt/flux';

    function __construct() {
        parent::__construct();
        $this->load->model("db_model");
        $this->load->library("flux/common");
        $this->load->library("flux_log");
    }

    function runCommand($command, $path) {
        $output = [];
        $return_var = null;
        exec("cd $path && $command", $output, $return_var);
        return ['output' => $output, 'status' => $return_var];
    }

    function getCommitDescriptionTittle($repoPath, $commitHash) {
        $result = $this->runCommand("git log -1 --pretty=%B $commitHash", $repoPath);
        
        if ($result['status'] !== 0) {
            throw new Exception('Erro ao buscar a descrição do commit: ' . implode("\n", $result['output']));
        }

        $title = trim($result['output'][0]);
        $description = trim(implode("\n", array_slice($result['output'], 1)));

        return [
            'title' => $title,
            'description' => $description
        ];
    }

    
    function getCurrentCommitHash($repoPath) {
        // Obtém o hash do commit atual
        $result = $this->runCommand('git rev-parse HEAD', $repoPath);
        
        if ($result['status'] !== 0) {
            throw new Exception('Erro ao obter o commit atual: ' . implode("\n", $result['output']));
        }
    
        return trim($result['output'][0]);
    }
    
    // Verificar se há novos commits na branch 'master'
    function checkForNewCommits($repoPath) {
        $fetchResult = $this->runCommand('git fetch origin', $repoPath);
        $this->flux_log->write_log("GIT_CHECK_NEW_COMMITS",  "fetchResult: " . json_encode($fetchResult));
        if ($fetchResult['status'] !== 0) {
            throw new Exception('Erro ao buscar atualizações do repositório: ' . implode("\n", $fetchResult['output']));
        }
    
        // Comparar as diferenças entre local e remoto
        $checkCommits = $this->runCommand('git log HEAD..origin/master --oneline', $repoPath);
    
        if (!empty($checkCommits['output'])) {
            return true;
        }
        return false;
    }
    
    function mergeBranch($repoPath) {
        // Salvar o hash do commit atual
        $previousCommit = $this->getCurrentCommitHash($repoPath);
        $this->flux_log->write_log("GIT_HASH",  "HASH ATUAL: " . json_encode($previousCommit));
        
        $query_select_hash = "SELECT * FROM git_version where commit_hash = '" . $previousCommit . "'";
        $result = $this->db->query($query_select_hash);
        if ($result->num_rows() > 0){
            $query_update_hash = "UPDATE git_version set is_current = 1";
            $this->flux_log->write_log("GIT_MERGE",  "atualizando hash atual");
            $this->db->query($query_update_hash);
        } else {
            $description = $this->getCommitDescriptionTittle($repoPath, $previousCommit);
            $query_insert_hash = "INSERT INTO git_version (`commit_hash`, `tittle` , `description`,`is_current`) VALUES ('" . $previousCommit . "', '". $description['title'] ."' ,'" . $description['description'] . "', '1')";
            $this->flux_log->write_log("GIT_MERGE",  "INSERINDO hash atual");
            $this->db->query($query_insert_hash);
        }

        $mergeResult = $this->runCommand('git merge origin/master', $repoPath);

        if ($mergeResult['status'] !== 0) {
            throw new Exception('Erro ao fazer merge: ' . implode("\n", $mergeResult['output']));
        }
        $current_hash = $this->getCurrentCommitHash($repoPath);
        $this->flux_log->write_log("GIT_HASH",  "HASH APOS O COMMIT: " . json_encode($current_hash));
        $query_check_new_hash = "SELECT * FROM git_version WHERE commit_hash = '" . $current_hash . "'";
        $description = $this->getCommitDescriptionTittle($repoPath, $current_hash);
        $new_hash_result = $this->db->query($query_check_new_hash);

        if ($new_hash_result->num_rows() > 0) {
            $query_update_new_hash = "UPDATE git_version SET is_current = 0 WHERE commit_hash = '" . $current_hash . "'";
            $this->flux_log->write_log("GIT_MERGE",  "Atualizando hash existente");
            $this->db->query($query_update_new_hash);
        } else {
            $query_insert_new_hash = "INSERT INTO git_version (`commit_hash`, `tittle` , `description`,`is_current`) VALUES ('" . $current_hash . "', '". $description['title'] ."' ,'" . $description['description'] . "', '0')";
            $this->flux_log->write_log("GIT_MERGE",  "Inserindo novo hash");
            $this->db->query($query_insert_new_hash);
        }

        return ['mergeOutput' => $mergeResult['output'], 'previousCommit' => $previousCommit];
    }
    
    function rollbackToPreviousCommit($repoPath, $hashCommit) {
        $this->flux_log->write_log("GIT_ROLLBACK",  "Hash:" . json_encode($hashCommit));

        $update_status = "UPDATE git_version set is_current = 1 where commit_hash != '" . $hashCommit . "'";
        $update_query_rollback = "UPDATE git_version set is_current = 0 where commit_hash = '" . $hashCommit . "'";

        $rollbackResult = $this->runCommand("git reset --hard $hashCommit", $repoPath);
        
        if ($rollbackResult['status'] !== 0) {
            throw new Exception('Erro ao fazer rollback: ' . implode("\n", $rollbackResult['output']));
        }else{
            $this->db->query($update_status);
            $this->db->query($update_query_rollback);
            $this->flux_log->write_log("GIT_ROLLBACK",  "RETORNADO AO HASH: " . json_encode($hashCommit));
        }
    
        return $rollbackResult['output'];
    }

    public function executeUpdate() {
        if ($this->input->is_ajax_request()) {
            try {
                $result = $this->processUpdate();
                $response = [
                    'status' => 'success',
                    'message' => $result
                ];
            } catch (Exception $e) {
                $response = [
                    'status' => 'error',
                    'message' => 'Erro ao verificar atualização: ' . $e->getMessage()
                ];

                return $response;
            }
        } else {
            // CLI output
            echo $this->processUpdate();
        }
    }

    public function executeRollback() {
        if ($this->input->is_ajax_request()) {
            try {
                $result = $this->processRollback();
                $response = [
                    'status' => 'success',
                    'message' => $result
                ];
            } catch (Exception $e) {
                $response = [
                    'status' => 'error',
                    'message' => 'Erro ao realizar Rollback: ' . $e->getMessage()
                ];

                return $response;
            }
        } else {
            // CLI output
            echo $this->processRollback();
        }
    }

    private function processUpdate() {
        try {
            if ($this->checkForNewCommits($this->repoPath)) {
                $this->flux_log->write_log("GIT_UPDATE",  "Novos commits encontrados. Realizando o merge...\n");
                $mergeData = $this->mergeBranch($this->repoPath);
                $this->flux_log->write_log("GIT_UPDATE",  "Merge realizado com sucesso\n");

                $response = [
                    'status' => 'success',
                    'message' => 'Merge realizado com sucesso.',
                    'data' => $mergeData['mergeOutput']
                ];
            } else {
                $this->flux_log->write_log("GIT_UPDATE",  "Nenhum novo commit encontrado\n");

                $response = [
                    'status' => 'info',
                    'message' => 'Nenhuma nova atualização encontrada.'
                ];
            }

        } catch (Exception $e) {
            $this->flux_log->write_log("GIT_ROLLBACK",  "erro: ". json_encode($e->getMessage()));

            $response = [
                'status' => 'error',
                'message' => 'Erro ao verificar atualizações: ' . $e->getMessage()
            ];
            
        }

        $this->output->set_content_type('application/json')->set_output(json_encode($response));
    }

    private function processRollback() {
        try {
            
            $get_last_hash = "SELECT * FROM flux.git_version where is_current = 1 and id < (select id from flux.git_version where is_current = 0) order by id desc limit 1";
            $result = $this->db->query($get_last_hash)->result_array();
            $this->flux_log->write_log("GIT_ROLLBACK",  "Commit encontrado. " . $result[0]['commit_hash'] . " Realizando o Rollback...\n");
            $this->rollbackToPreviousCommit($this->repoPath, $result[0]['commit_hash']);
            $this->flux_log->write_log("GIT_ROLLBACK",  "Rollback realizado com sucesso\n");

            $response = [
                'status' => 'success',
                'message' => 'Rollback realizado com sucesso.',
                'data' => $mergeData['mergeOutput']
            ];
            
        } catch (Exception $e) {
            $this->flux_log->write_log("GIT_ROLLBACK",  "erro: ". json_encode($e->getMessage()));

            $response = [
                'status' => 'error',
                'message' => 'Erro ao realizar Rollback: ' . $e->getMessage()
            ];
            
        }

        $this->output->set_content_type('application/json')->set_output(json_encode($response));
    }
}
